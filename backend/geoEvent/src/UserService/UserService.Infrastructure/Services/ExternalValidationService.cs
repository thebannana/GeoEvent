using System.Net;
using Microsoft.Extensions.Logging;
using UserService.Application.Interfaces.Services;

namespace UserService.Infrastructure.Services;

public class ExternalValidationService : IExternalValidationService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ExternalValidationService> _logger;

    public ExternalValidationService(
        HttpClient httpClient,
        ILogger<ExternalValidationService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<bool> EventExistsAsync(int eventId)
    {
        return await ExistsAsync($"api/public/events/{eventId}");
    }

    public async Task<bool> CommentExistsAsync(int commentId)
    {
        return await ExistsAsync($"api/comments/{commentId}");
    }

    public async Task<bool> ReviewExistsAsync(int reviewId)
    {
        return await ExistsAsync($"api/reviews/{reviewId}");
    }

    private async Task<bool> ExistsAsync(string url)
    {
        try
        {
            using var response = await _httpClient.GetAsync(url);

            if (response.StatusCode == HttpStatusCode.NotFound)
                return false;

            if (response.IsSuccessStatusCode)
                return true;

            _logger.LogWarning(
                "External validation call returned unexpected status {StatusCode} for {Url}",
                (int)response.StatusCode,
                url);

            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "External validation failed for {Url}", url);
            return false;
        }
    }
}