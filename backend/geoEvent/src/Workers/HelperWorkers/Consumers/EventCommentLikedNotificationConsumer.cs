using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventCommentLikedNotificationConsumer : IConsumer<EventCommentLikedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventCommentLikedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventCommentLikedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.CommentOwnerUserId,
            Type = NotificationType.EventCommentLiked,
            Title = $"{message.LikedByDisplayName} liked your comment",
            Description = $"On {message.EventTitle}: {message.CommentPreview}",
            ImageUrl = message.EventImageUrl
        }, context.CancellationToken);
    }
}