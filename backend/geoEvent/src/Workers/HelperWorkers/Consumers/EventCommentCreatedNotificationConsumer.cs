using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventCommentCreatedNotificationConsumer : IConsumer<EventCommentCreatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventCommentCreatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventCommentCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventCommentAdded,
            Title = $"{message.CommentAuthorDisplayName} commented on your event",
            Description = $"On {message.EventTitle}: {message.CommentPreview}",
            ImageUrl = message.EventImageUrl
        }, context.CancellationToken);
    }
}