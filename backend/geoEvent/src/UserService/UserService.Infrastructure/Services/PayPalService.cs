using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;
using UserService.Infrastructure.Options;

namespace UserService.Infrastructure.Services;

public class PayPalService : IPayPalService
{
    private readonly PayPalOptions _options;
    private readonly HttpClient _httpClient;
    private readonly ILogger<PayPalService> _logger;

    public PayPalService(
        IOptions<PayPalOptions> options,
        HttpClient httpClient,
        ILogger<PayPalService> logger)
    {
        _options = options.Value;
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<ServiceResult<PayPalStatusDto>> GetStatusAsync()
    {
        var credentialsConfigured =
            !string.IsNullOrWhiteSpace(_options.ClientId) &&
            !string.IsNullOrWhiteSpace(_options.ClientSecret);

        if (!credentialsConfigured)
        {
            return ServiceResult<PayPalStatusDto>.Ok(new PayPalStatusDto
            {
                Enabled = false,
                Mode = _options.Mode,
                CredentialsConfigured = false
            });
        }

        try
        {
            var token = await GetAccessTokenAsync();

            return ServiceResult<PayPalStatusDto>.Ok(new PayPalStatusDto
            {
                Enabled = !string.IsNullOrWhiteSpace(token),
                Mode = _options.Mode,
                CredentialsConfigured = true
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PayPal configuration validation failed.");

            return ServiceResult<PayPalStatusDto>.Ok(new PayPalStatusDto
            {
                Enabled = false,
                Mode = _options.Mode,
                CredentialsConfigured = true
            });
        }
    }

    private async Task<string> GetAccessTokenAsync()
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{_options.BaseUrl}/v1/oauth2/token");

        var basic = Convert.ToBase64String(
            Encoding.UTF8.GetBytes($"{_options.ClientId}:{_options.ClientSecret}"));

        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", basic);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        request.Content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "client_credentials"
        });

        using var response = await _httpClient.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("PayPal token request failed. Status: {Status}. Body: {Body}", response.StatusCode, body);
            throw new InvalidOperationException("Failed to authenticate with PayPal.");
        }

        using var doc = JsonDocument.Parse(body);

        if (doc.RootElement.TryGetProperty("access_token", out var tokenElement))
        {
            var token = tokenElement.GetString();
            if (!string.IsNullOrWhiteSpace(token))
                return token;
        }

        throw new InvalidOperationException("PayPal token response missing access_token.");
    }
}