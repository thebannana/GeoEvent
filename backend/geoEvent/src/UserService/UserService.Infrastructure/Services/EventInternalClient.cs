using System.Net.Http.Json;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;

namespace UserService.Infrastructure.Services;

public sealed class EventInternalClient : IEventInternalClient
{
    private readonly HttpClient _httpClient;

    public EventInternalClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<int> GetOrganizerEventsCountAsync(
        int userId,
        CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.GetAsync(
            $"api/internal/events/organizers/{userId}/count",
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException(
                $"EventService internal count call failed: {(int)response.StatusCode} {response.ReasonPhrase}. Body: {body}");
        }

        var count = await response.Content.ReadFromJsonAsync<int?>(cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("EventService returned an empty organizer count response.");

        return count;
    }

    public async Task<List<EventSegmentLookupDto>> GetAllSegmentsAsync(
        CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.GetAsync(
            "api/segments",
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException(
                $"EventService segments lookup failed: {(int)response.StatusCode} {response.ReasonPhrase}. Body: {body}");
        }

        var items = await response.Content.ReadFromJsonAsync<List<EventSegmentLookupDto>>(cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("EventService returned an empty segments response.");

        return items;
    }

    public async Task<InternalEventEngagementStatsDto> GetEngagementStatsAsync(
        CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.GetAsync(
            "api/internal/events/stats/engagement",
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException(
                $"EventService engagement stats call failed: {(int)response.StatusCode} {response.ReasonPhrase}. Body: {body}");
        }

        var stats = await response.Content.ReadFromJsonAsync<InternalEventEngagementStatsDto>(cancellationToken: cancellationToken)
            ?? throw new InvalidOperationException("EventService returned an empty engagement stats response.");

        return stats;
    }
}