using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Tickets;

public sealed class EventCreatedConsumer : IConsumer<EventCreatedMessage>
{
    private readonly ITicketInternalClient _ticketInternalClient;
    private readonly ILogger<EventCreatedConsumer> _logger;

    public EventCreatedConsumer(
        ITicketInternalClient ticketInternalClient,
        ILogger<EventCreatedConsumer> logger)
    {
        _ticketInternalClient = ticketInternalClient;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<EventCreatedMessage> context)
    {
        var msg = context.Message;

        _logger.LogInformation(
            "Consuming EventCreatedMessage for EventId {EventId}",
            msg.EventId);

        await _ticketInternalClient.CreateDefaultTicketForEventAsync(
            msg,
            context.CancellationToken);

        _logger.LogInformation(
            "Requested default ticket creation for EventId {EventId}",
            msg.EventId);
    }
}