using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventCommentCreatedConsumer : IConsumer<EventCommentCreatedMessage>
{
    private readonly INotificationService _notificationService;

    public EventCommentCreatedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventCommentCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventCommentAdded,
            Title = $"{message.CommentAuthorDisplayName} commented on your event",
            Description = $"On '{message.EventTitle}': \"{message.CommentPreview}\"",
            ImageUrl = message.EventImageUrl
        });
    }
}