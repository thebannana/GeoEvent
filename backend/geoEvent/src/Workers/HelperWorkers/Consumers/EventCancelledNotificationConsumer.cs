using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventCancelledNotificationConsumer : IConsumer<EventCancelledMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventCancelledNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventCancelledMessage> context)
    {
        var message = context.Message;
        if (message.OrganizerId is null)
            return;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerId.Value,
            Type = NotificationType.EventCancelled,
            Title = "Event Cancelled",
            Description = $"Your event {message.Title} has been cancelled. Reason: {message.Reason}"
        }, context.CancellationToken);
    }
}