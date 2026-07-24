using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using UserService.Application.DTOs;
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
        return await ExistsAsync($"api/internal/lookup/comments/{commentId}");
    }

    public async Task<bool> ReviewExistsAsync(int reviewId)
    {
        return await ExistsAsync($"api/internal/lookup/reviews/{reviewId}");
    }

    public async Task<ExternalEventLookupDto?> GetEventLookupAsync(int eventId)
    {
        return await GetAsync<ExternalEventLookupDto>($"api/internal/lookup/events/{eventId}");
    }

    public async Task<ExternalCommentLookupDto?> GetCommentLookupAsync(int commentId)
    {
        return await GetAsync<ExternalCommentLookupDto>($"api/internal/lookup/comments/{commentId}");
    }

    public async Task<ExternalReviewLookupDto?> GetReviewLookupAsync(int reviewId)
    {
        return await GetAsync<ExternalReviewLookupDto>($"api/internal/lookup/reviews/{reviewId}");
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

    private async Task<T?> GetAsync<T>(string url) where T : class
    {
        try
        {
            using var response = await _httpClient.GetAsync(url);

            if (response.StatusCode == HttpStatusCode.NotFound)
                return null;

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "External lookup call returned unexpected status {StatusCode} for {Url}",
                    (int)response.StatusCode,
                    url);

                return null;
            }

            return await response.Content.ReadFromJsonAsync<T>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "External lookup failed for {Url}", url);
            return null;
        }
    }
}