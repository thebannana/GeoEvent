using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class TicketCancelledNotificationConsumer : IConsumer<TicketCancelledMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public TicketCancelledNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<TicketCancelledMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.TicketCancelled,
            Title = "Ticket Cancelled",
            Description = $"Your ticket has been cancelled. Reason: {message.Reason}"
        }, context.CancellationToken);
    }
}