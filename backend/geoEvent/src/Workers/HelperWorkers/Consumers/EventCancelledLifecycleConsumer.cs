using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Tickets;

public sealed class EventCancelledLifecycleConsumer : IConsumer<EventCancelledMessage>
{
    private readonly ITicketInternalClient _ticketInternalClient;
    private readonly ILogger<EventCancelledLifecycleConsumer> _logger;

    public EventCancelledLifecycleConsumer(
        ITicketInternalClient ticketInternalClient,
        ILogger<EventCancelledLifecycleConsumer> logger)
    {
        _ticketInternalClient = ticketInternalClient;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<EventCancelledMessage> context)
    {
        var msg = context.Message;

        _logger.LogInformation(
            "Consuming EventCancelledMessage (Lifecycle) for EventId {EventId}",
            msg.EventId);

        await _ticketInternalClient.CancelTicketsByEventAsync(
            msg.EventId,
            context.CancellationToken);

        _logger.LogInformation(
            "Requested ticket cancellation for EventId {EventId}",
            msg.EventId);
    }
}
