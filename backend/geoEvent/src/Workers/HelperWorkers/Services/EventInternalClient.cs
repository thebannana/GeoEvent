using System.Net.Http.Json;
using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;

namespace GeoEvent.HelperWorkers.Services;

public sealed class EventInternalClient
    : IEventInternalClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<EventInternalClient> _logger;

    public EventInternalClient(
        HttpClient httpClient,
        ILogger<EventInternalClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<IReadOnlyList<EventLifecycleCandidateDto>>
        GetReadyToCompleteAsync(
            DateTime now,
            CancellationToken cancellationToken = default)
    {
        var query =
            $"api/internal/events/ready-to-complete" +
            $"?now={Uri.EscapeDataString(now.ToString("O"))}";

        using var response = await _httpClient.GetAsync(
            query,
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body =
                await response.Content.ReadAsStringAsync(
                    cancellationToken);

            _logger.LogError(
                "Could not get events ready to complete. " +
                "StatusCode: {StatusCode}, Response: {Response}",
                (int)response.StatusCode,
                body);

            response.EnsureSuccessStatusCode();
        }

        return await response.Content.ReadFromJsonAsync<
                   List<EventLifecycleCandidateDto>>(
                   cancellationToken: cancellationToken)
               ?? [];
    }

    public async Task CompleteAsync(
        int eventId,
        CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.PostAsync(
            $"api/internal/events/{eventId}/complete",
            content: null,
            cancellationToken);

        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body =
            await response.Content.ReadAsStringAsync(
                cancellationToken);

        _logger.LogError(
            "Event completion failed for EventId {EventId}. " +
            "StatusCode: {StatusCode}, Response: {Response}",
            eventId,
            (int)response.StatusCode,
            body);

        response.EnsureSuccessStatusCode();
    }
}