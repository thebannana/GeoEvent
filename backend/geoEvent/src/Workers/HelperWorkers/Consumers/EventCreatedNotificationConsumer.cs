using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventCreatedNotificationConsumer : IConsumer<EventCreatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventCreatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventCreatedMessage> context)
    {
        var message = context.Message;
        if (message.OrganizerId is null)
            return;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerId.Value,
            Type = NotificationType.EventCreated,
            Title = "Event Published",
            Description = $"Your event {message.Title} is now live."
        }, context.CancellationToken);
    }
}