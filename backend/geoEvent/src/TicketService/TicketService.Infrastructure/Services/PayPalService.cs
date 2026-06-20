using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using TicketService.Application.Common;
using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.Services;

public class PayPalService : IPayPalService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _config;
    private readonly ILogger<PayPalService> _logger;
    private readonly string _baseUrl;

    public PayPalService(HttpClient httpClient, IConfiguration config, ILogger<PayPalService> logger)
    {
        _httpClient = httpClient;
        _config = config;
        _logger = logger;
        
        var mode = _config["PayPal:Mode"] ?? "sandbox";
        _baseUrl = mode.ToLower() == "live" 
            ? "https://api-m.paypal.com" 
            : "https://api-m.sandbox.paypal.com";
    }

    private async Task<string> GetAccessTokenAsync()
    {
        var clientId = _config["PayPal:ClientId"];
        var clientSecret = _config["PayPal:ClientSecret"];

        if (string.IsNullOrEmpty(clientId) || string.IsNullOrEmpty(clientSecret))
        {
            _logger.LogWarning("PayPal credentials not found. Using mock mode.");
            return "mock_token";
        }

        var auth = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{clientId}:{clientSecret}"));
        var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v1/oauth2/token");
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", auth);
        request.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(content);
        return doc.RootElement.GetProperty("access_token").GetString() ?? "";
    }

    public async Task<ServiceResult<PayPalOrderResponseDto>> CreateOrderAsync(decimal amount, string currency, string referenceId)
    {
        var token = await GetAccessTokenAsync();
        
        if (token == "mock_token")
        {
            return ServiceResult<PayPalOrderResponseDto>.Ok(new PayPalOrderResponseDto
            {
                OrderId = "MOCK_ORDER_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                Status = "CREATED",
                ApproveLink = "https://sandbox.paypal.com/mock-approve"
            });
        }

        var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

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
                        currency_code = currency,
                        value = amount.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture)
                    }
                }
            }
        };

        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(request);
        var content = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal CreateOrder failed: {Content}", content);
            return ServiceResult<PayPalOrderResponseDto>.Fail("Failed to create PayPal order.");
        }

        using var doc = JsonDocument.Parse(content);
        var orderId = doc.RootElement.GetProperty("id").GetString() ?? "";
        var status = doc.RootElement.GetProperty("status").GetString() ?? "";
        
        var links = doc.RootElement.GetProperty("links").EnumerateArray();
        var approveLink = links.FirstOrDefault(l => l.GetProperty("rel").GetString() == "approve")
                               .GetProperty("href").GetString() ?? "";

        return ServiceResult<PayPalOrderResponseDto>.Ok(new PayPalOrderResponseDto
        {
            OrderId = orderId,
            Status = status,
            ApproveLink = approveLink
        });
    }

    public async Task<ServiceResult<PayPalCaptureResponseDto>> CaptureOrderAsync(string orderId)
    {
        var token = await GetAccessTokenAsync();
        
        if (token == "mock_token" || orderId.StartsWith("MOCK_ORDER_"))
        {
            return ServiceResult<PayPalCaptureResponseDto>.Ok(new PayPalCaptureResponseDto
            {
                Id = "MOCK_CAPTURE_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                Status = "COMPLETED"
            });
        }

        var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/v2/checkout/orders/{orderId}/capture");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Content = new StringContent("{}", Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(request);
        var content = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal CaptureOrder failed: {Content}", content);
            return ServiceResult<PayPalCaptureResponseDto>.Fail("Failed to capture PayPal order.");
        }

        using var doc = JsonDocument.Parse(content);
        var id = doc.RootElement.GetProperty("id").GetString() ?? "";
        var status = doc.RootElement.GetProperty("status").GetString() ?? "";

        return ServiceResult<PayPalCaptureResponseDto>.Ok(new PayPalCaptureResponseDto
        {
            Id = id,
            Status = status
        });
    }
}
