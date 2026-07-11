using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.Services;

public class PayPalService : IPayPalService
{
    private static readonly HashSet<string> SupportedPayPalCurrencies = new(StringComparer.OrdinalIgnoreCase)
    {
        "AUD", "BRL", "CAD", "CZK", "DKK", "EUR", "HKD", "HUF", "ILS",
        "JPY", "MXN", "TWD", "NZD", "NOK", "PHP", "PLN", "GBP", "SGD",
        "SEK", "CHF", "THB", "USD"
    };

    private const decimal BamToEurRate = 0.51129m;

    private readonly HttpClient _httpClient;
    private readonly ILogger<PayPalService> _logger;
    private readonly string _baseUrl;
    private readonly string _clientId;
    private readonly string _clientSecret;

    public PayPalService(
        HttpClient httpClient,
        IConfiguration config,
        ILogger<PayPalService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;

        var mode = config["PayPal:Mode"] ?? "sandbox";
        _baseUrl = mode.Equals("live", StringComparison.OrdinalIgnoreCase)
            ? "https://api-m.paypal.com"
            : "https://api-m.sandbox.paypal.com";

        _clientId = config["PayPal:ClientId"] ?? string.Empty;
        _clientSecret = config["PayPal:ClientSecret"] ?? string.Empty;
    }

    private async Task<string> GetAccessTokenAsync()
    {
        if (string.IsNullOrWhiteSpace(_clientId) || string.IsNullOrWhiteSpace(_clientSecret))
            throw new InvalidOperationException("PayPal credentials are not configured.");

        var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/oauth2/token");
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", auth);
        request.Content = new StringContent(
            "grant_type=client_credentials",
            Encoding.UTF8,
            "application/x-www-form-urlencoded");

        using var response = await _httpClient.SendAsync(request);
        var content = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "PayPal token request failed. StatusCode={StatusCode}, Response={Content}",
                (int)response.StatusCode,
                content);

            throw new InvalidOperationException("Failed to obtain PayPal access token.");
        }

        using var doc = JsonDocument.Parse(content);

        var token = doc.RootElement.TryGetProperty("access_token", out var accessTokenEl)
            ? accessTokenEl.GetString() ?? string.Empty
            : string.Empty;

        if (string.IsNullOrWhiteSpace(token))
        {
            _logger.LogError(
                "PayPal token response did not contain access_token. Response={Content}",
                content);

            throw new InvalidOperationException("Failed to obtain PayPal access token.");
        }

        return token;
    }

    public static string NormalizeCurrencyForPayPal(string currency)
    {
        if (string.IsNullOrWhiteSpace(currency))
            return "EUR";

        if (currency.Equals("BAM", StringComparison.OrdinalIgnoreCase))
            return "EUR";

        return currency.Trim().ToUpperInvariant();
    }

    public static decimal NormalizeAmountForPayPal(decimal amount, string currency)
    {
        if (amount <= 0)
            return 0m;

        if (currency.Equals("BAM", StringComparison.OrdinalIgnoreCase))
            return Math.Round(amount * BamToEurRate, 2, MidpointRounding.AwayFromZero);

        return Math.Round(amount, 2, MidpointRounding.AwayFromZero);
    }

    public static bool AmountMatchesForPayPal(
        decimal reservationAmount,
        string reservationCurrency,
        decimal paypalAmount,
        string paypalCurrency)
    {
        var expectedCurrency = NormalizeCurrencyForPayPal(reservationCurrency);
        var expectedAmount = NormalizeAmountForPayPal(reservationAmount, reservationCurrency);

        return string.Equals(expectedCurrency, paypalCurrency, StringComparison.OrdinalIgnoreCase)
            && expectedAmount == Math.Round(paypalAmount, 2, MidpointRounding.AwayFromZero);
    }

    public async Task<ServiceResult<PayPalOrderResponseDto>> CreateOrderAsync(
        decimal amount,
        string currency,
        string referenceId,
        string returnUrl,
        string cancelUrl)
    {
        try
        {
            if (amount <= 0)
                return ServiceResult<PayPalOrderResponseDto>.Fail("PayPal order amount must be greater than zero.", StatusCodes.Status400BadRequest);

            if (string.IsNullOrWhiteSpace(currency))
                return ServiceResult<PayPalOrderResponseDto>.Fail("Currency is required.", StatusCodes.Status400BadRequest);

            if (string.IsNullOrWhiteSpace(referenceId))
                return ServiceResult<PayPalOrderResponseDto>.Fail("Reference ID is required.", StatusCodes.Status400BadRequest);

            if (string.IsNullOrWhiteSpace(returnUrl) || string.IsNullOrWhiteSpace(cancelUrl))
                return ServiceResult<PayPalOrderResponseDto>.Fail("PayPal return and cancel URLs are required.", StatusCodes.Status500InternalServerError);

            currency = currency.Trim();
            referenceId = referenceId.Trim();
            returnUrl = returnUrl.Trim();
            cancelUrl = cancelUrl.Trim();

            var paypalCurrency = NormalizeCurrencyForPayPal(currency);
            var paypalAmount = NormalizeAmountForPayPal(amount, currency);

            if (!SupportedPayPalCurrencies.Contains(paypalCurrency))
                return ServiceResult<PayPalOrderResponseDto>.Fail($"PayPal does not support currency '{currency}'.", StatusCodes.Status400BadRequest);

            if (paypalAmount <= 0)
                return ServiceResult<PayPalOrderResponseDto>.Fail("Converted PayPal amount must be greater than zero.", StatusCodes.Status400BadRequest);

            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Add("PayPal-Request-Id", $"create-{referenceId}-{Guid.NewGuid():N}");

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = referenceId,
                        amount = new
                        {
                            currency_code = paypalCurrency,
                            value = paypalAmount.ToString("0.00", CultureInfo.InvariantCulture)
                        }
                    }
                },
                payment_source = new
                {
                    paypal = new
                    {
                        experience_context = new
                        {
                            return_url = returnUrl,
                            cancel_url = cancelUrl,
                            user_action = "PAY_NOW"
                        }
                    }
                }
            };

            request.Content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            using var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError(
                    "PayPal CreateOrder failed. ReferenceId={ReferenceId}, StatusCode={StatusCode}, Response={Content}",
                    referenceId,
                    (int)response.StatusCode,
                    content);

                return ServiceResult<PayPalOrderResponseDto>.Fail(
                    "Failed to create PayPal order.",
                    (int)response.StatusCode);
            }

            using var doc = JsonDocument.Parse(content);
            var root = doc.RootElement;

            var orderId = root.TryGetProperty("id", out var idEl)
                ? idEl.GetString()?.Trim() ?? string.Empty
                : string.Empty;

            var status = root.TryGetProperty("status", out var statusEl)
                ? statusEl.GetString()?.Trim() ?? string.Empty
                : string.Empty;

            string approveLink = string.Empty;

            if (root.TryGetProperty("links", out var linksElement) &&
                linksElement.ValueKind == JsonValueKind.Array)
            {
                foreach (var link in linksElement.EnumerateArray())
                {
                    var rel = link.TryGetProperty("rel", out var relEl)
                        ? relEl.GetString()?.Trim() ?? string.Empty
                        : string.Empty;

                    if (!string.Equals(rel, "approve", StringComparison.OrdinalIgnoreCase) &&
                        !string.Equals(rel, "payer-action", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    approveLink = link.TryGetProperty("href", out var hrefEl)
                        ? hrefEl.GetString()?.Trim() ?? string.Empty
                        : string.Empty;

                    if (!string.IsNullOrWhiteSpace(approveLink))
                        break;
                }
            }

            if (string.IsNullOrWhiteSpace(orderId) || string.IsNullOrWhiteSpace(approveLink))
            {
                _logger.LogError(
                    "PayPal order response missing required fields. Response={Content}",
                    content);

                return ServiceResult<PayPalOrderResponseDto>.Fail(
                    "PayPal approval response is invalid.",
                    StatusCodes.Status500InternalServerError);
            }

            return ServiceResult<PayPalOrderResponseDto>.Ok(new PayPalOrderResponseDto
            {
                OrderId = orderId,
                Status = status,
                ApproveLink = approveLink
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create PayPal order.");
            return ServiceResult<PayPalOrderResponseDto>.Fail(
                "Failed to create PayPal order.",
                StatusCodes.Status500InternalServerError);
        }
    }

    public async Task<ServiceResult<PayPalOrderDetailsDto>> GetOrderAsync(string orderId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(orderId))
                return ServiceResult<PayPalOrderDetailsDto>.Fail("Order ID is required.", 400);

            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(HttpMethod.Get, $"{_baseUrl}/v2/checkout/orders/{orderId}");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

            using var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError(
                    "PayPal GetOrder failed. OrderId={OrderId}, StatusCode={StatusCode}, Response={Content}",
                    orderId,
                    (int)response.StatusCode,
                    content);

                return ServiceResult<PayPalOrderDetailsDto>.Fail(
                    "Failed to get PayPal order details.",
                    (int)response.StatusCode);
            }

            using var doc = JsonDocument.Parse(content);
            var root = doc.RootElement;

            var status = root.TryGetProperty("status", out var statusEl)
                ? statusEl.GetString() ?? string.Empty
                : string.Empty;

            string referenceId = string.Empty;
            string currencyCode = string.Empty;
            decimal amountValue = 0m;

            if (root.TryGetProperty("purchase_units", out var purchaseUnits) &&
                purchaseUnits.ValueKind == JsonValueKind.Array &&
                purchaseUnits.GetArrayLength() > 0)
            {
                var purchaseUnit = purchaseUnits[0];

                if (purchaseUnit.TryGetProperty("reference_id", out var refEl))
                    referenceId = refEl.GetString() ?? string.Empty;

                if (purchaseUnit.TryGetProperty("amount", out var amountObj))
                {
                    if (amountObj.TryGetProperty("currency_code", out var currencyEl))
                        currencyCode = currencyEl.GetString() ?? string.Empty;

                    if (amountObj.TryGetProperty("value", out var amountEl))
                    {
                        decimal.TryParse(
                            amountEl.GetString(),
                            NumberStyles.Number,
                            CultureInfo.InvariantCulture,
                            out amountValue);
                    }
                }
            }

            return ServiceResult<PayPalOrderDetailsDto>.Ok(new PayPalOrderDetailsDto
            {
                OrderId = orderId,
                Status = status,
                Currency = currencyCode,
                Amount = Math.Round(amountValue, 2, MidpointRounding.AwayFromZero),
                ReferenceId = referenceId
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get PayPal order details. OrderId={OrderId}", orderId);
            return ServiceResult<PayPalOrderDetailsDto>.Fail("Failed to get PayPal order details.", 500);
        }
    }

    public async Task<ServiceResult<PayPalRefundResponseDto>> RefundCaptureAsync(
        string captureId,
        decimal? amount,
        string currency,
        string? reason)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(captureId))
                return ServiceResult<PayPalRefundResponseDto>.Fail("Capture ID is required.", 400);

            if (amount.HasValue && amount.Value <= 0)
                return ServiceResult<PayPalRefundResponseDto>.Fail("Refund amount must be greater than zero.", 400);

            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(
                HttpMethod.Post,
                $"{_baseUrl}/v2/payments/captures/{captureId}/refund");

            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Add("PayPal-Request-Id", $"refund-{captureId}-{Guid.NewGuid():N}");

            object payload;
            if (amount.HasValue)
            {
                payload = new
                {
                    amount = new
                    {
                        value = NormalizeAmountForPayPal(amount.Value, currency).ToString("0.00", CultureInfo.InvariantCulture),
                        currency_code = NormalizeCurrencyForPayPal(currency)
                    },
                    note_to_payer = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim()
                };
            }
            else
            {
                payload = new { };
            }

            request.Content = new StringContent(
                JsonSerializer.Serialize(payload, new JsonSerializerOptions
                {
                    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
                }),
                Encoding.UTF8,
                "application/json");

            using var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError(
                    "PayPal RefundCapture failed. CaptureId={CaptureId}, StatusCode={StatusCode}, Response={Content}",
                    captureId,
                    (int)response.StatusCode,
                    content);

                return ServiceResult<PayPalRefundResponseDto>.Fail(
                    "Failed to refund PayPal capture.",
                    (int)response.StatusCode);
            }

            using var doc = JsonDocument.Parse(content);
            var root = doc.RootElement;

            var refundId = root.TryGetProperty("id", out var refundIdEl)
                ? refundIdEl.GetString() ?? string.Empty
                : string.Empty;

            var status = root.TryGetProperty("status", out var refundStatusEl)
                ? refundStatusEl.GetString() ?? string.Empty
                : string.Empty;

            if (string.IsNullOrWhiteSpace(refundId))
                return ServiceResult<PayPalRefundResponseDto>.Fail("PayPal refund response is invalid.", 500);

            return ServiceResult<PayPalRefundResponseDto>.Ok(new PayPalRefundResponseDto
            {
                RefundId = refundId,
                Status = status
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to refund PayPal capture. CaptureId={CaptureId}", captureId);
            return ServiceResult<PayPalRefundResponseDto>.Fail("Failed to refund PayPal capture.", 500);
        }
    }

    public async Task<ServiceResult<PayPalCaptureResponseDto>> CaptureOrderAsync(string orderId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(orderId))
                return ServiceResult<PayPalCaptureResponseDto>.Fail("Order ID is required.", 400);

            orderId = orderId.Trim();

            var token = await GetAccessTokenAsync();

            using var request = new HttpRequestMessage(
                HttpMethod.Post,
                $"{_baseUrl}/v2/checkout/orders/{orderId}/capture");

            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            request.Headers.Add("PayPal-Request-Id", $"capture-{orderId}-{Guid.NewGuid():N}");
            request.Content = new StringContent("{}", Encoding.UTF8, "application/json");

            using var response = await _httpClient.SendAsync(request);
            var content = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError(
                    "PayPal CaptureOrder failed. OrderId={OrderId}, StatusCode={StatusCode}, Response={Content}",
                    orderId,
                    (int)response.StatusCode,
                    content);

                return ServiceResult<PayPalCaptureResponseDto>.Fail(
                    "Failed to capture PayPal order.",
                    (int)response.StatusCode);
            }

            using var doc = JsonDocument.Parse(content);
            var root = doc.RootElement;

            var status = root.TryGetProperty("status", out var statusEl)
                ? statusEl.GetString()?.Trim() ?? string.Empty
                : string.Empty;

            string captureId = string.Empty;

            if (root.TryGetProperty("purchase_units", out var purchaseUnits) &&
                purchaseUnits.ValueKind == JsonValueKind.Array)
            {
                foreach (var purchaseUnit in purchaseUnits.EnumerateArray())
                {
                    if (!purchaseUnit.TryGetProperty("payments", out var payments) ||
                        !payments.TryGetProperty("captures", out var captures) ||
                        captures.ValueKind != JsonValueKind.Array)
                    {
                        continue;
                    }

                    foreach (var capture in captures.EnumerateArray())
                    {
                        var candidateId = capture.TryGetProperty("id", out var captureIdEl)
                            ? captureIdEl.GetString()?.Trim() ?? string.Empty
                            : string.Empty;

                        var candidateStatus = capture.TryGetProperty("status", out var captureStatusEl)
                            ? captureStatusEl.GetString()?.Trim() ?? string.Empty
                            : string.Empty;

                        if (!string.IsNullOrWhiteSpace(candidateId) &&
                            string.Equals(candidateStatus, "COMPLETED", StringComparison.OrdinalIgnoreCase))
                        {
                            captureId = candidateId;
                            break;
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(captureId))
                        break;
                }
            }

            if (string.IsNullOrWhiteSpace(captureId))
            {
                _logger.LogError(
                    "PayPal capture response missing capture ID. OrderId={OrderId}, Response={Content}",
                    orderId,
                    content);

                return ServiceResult<PayPalCaptureResponseDto>.Fail(
                    "PayPal capture response is invalid.",
                    500);
            }

            return ServiceResult<PayPalCaptureResponseDto>.Ok(new PayPalCaptureResponseDto
            {
                Id = captureId,
                Status = status
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to capture PayPal order. OrderId={OrderId}", orderId);
            return ServiceResult<PayPalCaptureResponseDto>.Fail("Failed to capture PayPal order.", 500);
        }
    }
}