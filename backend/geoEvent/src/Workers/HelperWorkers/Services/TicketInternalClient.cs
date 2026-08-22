using System.Net.Http.Json;
using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Services;

public sealed class TicketInternalClient : ITicketInternalClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<TicketInternalClient> _logger;

    public TicketInternalClient(
        HttpClient httpClient,
        ILogger<TicketInternalClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task CreateDefaultTicketForEventAsync(
        EventCreatedMessage message,
        CancellationToken cancellationToken = default)
    {
        var request = new CreateDefaultEventTicketRequest
        {
            EventId = message.EventId,
            Price = message.Price,
            Capacity = message.Capacity,
            StartDateTime = message.StartDateTime
        };

        using var response = await _httpClient.PostAsJsonAsync(
            "api/internal/event-tickets/default",
            request,
            cancellationToken);

        if (response.IsSuccessStatusCode)
            return;

        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        _logger.LogError(
            "TicketService internal request failed for EventId {EventId}. StatusCode: {StatusCode}, Response: {Response}",
            message.EventId,
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }

    public async Task ExpireReservationsAsync(
    CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.PostAsync(
            "api/internal/reservations/expire",
            content: null,
            cancellationToken);

        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var responseBody =
            await response.Content.ReadAsStringAsync(
                cancellationToken);

        _logger.LogError(
            "Reservation expiration request failed. " +
            "StatusCode: {StatusCode}, Response: {Response}",
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }
}