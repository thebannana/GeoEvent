using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventLikedNotificationConsumer : IConsumer<EventLikedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventLikedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventLikedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventLiked,
            Title = $"{message.LikedByDisplayName} liked your event",
            Description = $"Your event {message.EventTitle} got a new like.",
            ImageUrl = message.EventImageUrl
        }, context.CancellationToken);
    }
}