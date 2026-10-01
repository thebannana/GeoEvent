using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Tickets;

public sealed class EventUpdatedLifecycleConsumer : IConsumer<EventUpdatedMessage>
{
    private readonly ITicketInternalClient _ticketInternalClient;
    private readonly ILogger<EventUpdatedLifecycleConsumer> _logger;

    public EventUpdatedLifecycleConsumer(
        ITicketInternalClient ticketInternalClient,
        ILogger<EventUpdatedLifecycleConsumer> logger)
    {
        _ticketInternalClient = ticketInternalClient;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<EventUpdatedMessage> context)
    {
        var msg = context.Message;

        _logger.LogInformation(
            "Consuming EventUpdatedMessage (Lifecycle) for EventId {EventId}",
            msg.EventId);

        await _ticketInternalClient.UpdateDefaultTicketAsync(
            msg.EventId,
            msg.Capacity,
            msg.Price,
            context.CancellationToken);

        _logger.LogInformation(
            "Requested default ticket update for EventId {EventId}",
            msg.EventId);
    }
}
