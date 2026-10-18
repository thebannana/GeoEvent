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

    public async Task ExpireEventDataAsync(
    int eventId,
    CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.PostAsync(
            $"api/internal/reservations/{eventId}/expire-after-event",
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
            "Event data expiration failed for EventId {EventId}. " +
            "StatusCode: {StatusCode}, Response: {Response}",
            eventId,
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }

    public async Task CancelTicketsByEventAsync(
    int eventId,
    CancellationToken cancellationToken = default)
    {
        using var response = await _httpClient.PostAsync(
            $"api/internal/event-tickets/cancel-by-event/{eventId}",
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
            "Ticket cancellation failed for EventId {EventId}. " +
            "StatusCode: {StatusCode}, Response: {Response}",
            eventId,
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }

    public async Task UpdateDefaultTicketAsync(
    int eventId,
    int capacity,
    decimal price,
    CancellationToken cancellationToken = default)
    {
        var request = new UpdateDefaultEventTicketRequest
        {
            Price = price,
            Capacity = capacity
        };

        using var response = await _httpClient.PutAsJsonAsync(
            $"api/internal/event-tickets/default/{eventId}",
            request,
            cancellationToken);

        if (response.IsSuccessStatusCode)
        {
            return;
        }

        // Permanent conditions that retrying cannot fix:
        //  - 404: the event has no default ticket yet (e.g. still Pending/unpublished).
        //    The ticket is created from EventCreatedMessage when the event is published.
        //  - 409: the new capacity is lower than the number of tickets already sold.
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound ||
            response.StatusCode == System.Net.HttpStatusCode.Conflict)
        {
            _logger.LogWarning(
                "Default ticket update skipped for EventId {EventId}. StatusCode: {StatusCode}",
                eventId,
                (int)response.StatusCode);
            return;
        }

        var responseBody =
            await response.Content.ReadAsStringAsync(
                cancellationToken);

        _logger.LogError(
            "Ticket update failed for EventId {EventId}. " +
            "StatusCode: {StatusCode}, Response: {Response}",
            eventId,
            (int)response.StatusCode,
            responseBody);

        response.EnsureSuccessStatusCode();
    }
}