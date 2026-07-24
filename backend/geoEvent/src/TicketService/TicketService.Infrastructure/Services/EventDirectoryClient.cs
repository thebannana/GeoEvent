using System.Text.Json;
using Microsoft.Extensions.Logging;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.Services;

public class EventDirectoryClient : IEventDirectoryClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<EventDirectoryClient> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public EventDirectoryClient(HttpClient httpClient, ILogger<EventDirectoryClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<EventSummaryDto?> GetEventAsync(int eventId, CancellationToken cancellationToken = default)
    {
        var requestUri = $"/api/public/events/{eventId}";
        var response = await _httpClient.GetAsync(requestUri, cancellationToken);
        var raw = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
            return null;

        var result = JsonSerializer.Deserialize<EventSummaryDto>(raw, JsonOptions);

        return result;
    }
}