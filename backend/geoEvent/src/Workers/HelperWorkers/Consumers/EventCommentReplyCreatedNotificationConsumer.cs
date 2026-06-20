using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventCommentReplyCreatedNotificationConsumer : IConsumer<EventCommentReplyCreatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventCommentReplyCreatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventCommentReplyCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.ParentCommentOwnerUserId,
            Type = NotificationType.EventCommentReply,
            Title = $"{message.ReplyAuthorDisplayName} replied to your comment",
            Description = $"On {message.EventTitle}: {message.ReplyPreview}",
            ImageUrl = message.EventImageUrl
        }, context.CancellationToken);
    }
}