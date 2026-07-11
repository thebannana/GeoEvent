using System.Net.Http.Json;
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
}