using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventCommentReplyCreatedConsumer : IConsumer<EventCommentReplyCreatedMessage>
{
    private readonly INotificationService _notificationService;

    public EventCommentReplyCreatedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventCommentReplyCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.ParentCommentOwnerUserId,
            Type = NotificationType.EventCommentReply,
            Title = $"{message.ReplyAuthorDisplayName} replied to your comment",
            Description = $"On '{message.EventTitle}': \"{message.ReplyPreview}\"",
            ImageUrl = message.EventImageUrl
        });
    }
}