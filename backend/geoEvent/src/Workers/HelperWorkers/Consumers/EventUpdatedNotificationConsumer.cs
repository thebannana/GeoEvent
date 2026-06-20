using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventUpdatedNotificationConsumer : IConsumer<EventUpdatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventUpdatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventUpdatedMessage> context)
    {
        var message = context.Message;
        if (message.OrganizerId is null)
            return;

        var description = string.IsNullOrWhiteSpace(message.ChangeSummary)
            ? $"{message.Title} has been updated."
            : $"{message.Title} has been updated. {message.ChangeSummary}";

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerId.Value,
            Type = NotificationType.EventUpdated,
            Title = "Event Updated",
            Description = description
        }, context.CancellationToken);
    }
}