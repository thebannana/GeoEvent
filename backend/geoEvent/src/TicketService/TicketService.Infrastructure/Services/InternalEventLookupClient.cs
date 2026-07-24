using System.Text.Json;
using Microsoft.Extensions.Logging;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Services;

namespace TicketService.Infrastructure.Services;

public class InternalEventLookupClient : IInternalEventLookupClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<InternalEventLookupClient> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public InternalEventLookupClient(
        HttpClient httpClient,
        ILogger<InternalEventLookupClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<EventSummaryDto?> GetEventAsync(int eventId, CancellationToken cancellationToken = default)
    {
        var requestUri = $"/api/internal/lookup/events/{eventId}";
        var response = await _httpClient.GetAsync(requestUri, cancellationToken);
        var raw = await response.Content.ReadAsStringAsync(cancellationToken);

        _logger.LogInformation(
            "InternalEventLookupClient GetEventAsync eventId={EventId}, statusCode={StatusCode}, baseAddress={BaseAddress}, requestUri={RequestUri}, body={Body}",
            eventId,
            (int)response.StatusCode,
            _httpClient.BaseAddress,
            requestUri,
            raw);

        if (!response.IsSuccessStatusCode)
            return null;

        var result = JsonSerializer.Deserialize<EventSummaryDto>(raw, JsonOptions);

        _logger.LogInformation(
            "InternalEventLookupClient parsed eventId={EventId}, parsedTitle={Title}, parsedCoverImageUrl={CoverImageUrl}",
            eventId,
            result?.Title,
            result?.CoverImageUrl);

        return result;
    }
}