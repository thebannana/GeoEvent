using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventCommentLikedConsumer : IConsumer<EventCommentLikedMessage>
{
    private readonly INotificationService _notificationService;

    public EventCommentLikedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventCommentLikedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.CommentOwnerUserId,
            Type = NotificationType.EventCommentLiked,
            Title = $"{message.LikedByDisplayName} liked your comment",
            Description = $"On '{message.EventTitle}': \"{message.CommentPreview}\"",
            ImageUrl = message.EventImageUrl
        });
    }
}