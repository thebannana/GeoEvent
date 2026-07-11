using System.Net.Http.Json;
using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Services;

public sealed class UserPreferenceInternalClient : IUserPreferenceInternalClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<UserPreferenceInternalClient> _logger;

    public UserPreferenceInternalClient(
        HttpClient httpClient,
        ILogger<UserPreferenceInternalClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task ApplyInteractionPreferenceAsync(
        UserEventPreferenceInteractionMessage message,
        CancellationToken cancellationToken = default)
    {
        var request = new ApplyUserEventPreferenceInteractionRequest
        {
            UserId = message.UserId,
            EventId = message.EventId,
            SegmentId = message.SegmentId,
            GenreId = message.GenreId,
            SubGenreId = message.SubGenreId,
            InteractionType = message.InteractionType,
            OccurredAt = message.OccurredAt
        };

        using var response = await _httpClient.PostAsJsonAsync(
            "api/internal/preferences/interactions",
            request,
            cancellationToken);

        if (response.IsSuccessStatusCode)
            return;

        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        _logger.LogError(
            "UserService internal request failed for UserId {UserId}, EventId {EventId}. StatusCode: {StatusCode}, Response: {Response}",
            message.UserId,
            message.EventId,
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }
}