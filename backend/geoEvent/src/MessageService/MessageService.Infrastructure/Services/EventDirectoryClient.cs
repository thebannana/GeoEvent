using System.Text.Json;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;

namespace MessageService.Infrastructure.Services;

public class EventDirectoryClient : IEventDirectoryClient
{
    private readonly HttpClient _httpClient;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public EventDirectoryClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<EventSummaryDto?> GetEventAsync(int eventId, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"/api/public/events/{eventId}", cancellationToken);
        if (!response.IsSuccessStatusCode)
            return null;

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        return await JsonSerializer.DeserializeAsync<EventSummaryDto>(stream, JsonOptions, cancellationToken);
    }
}