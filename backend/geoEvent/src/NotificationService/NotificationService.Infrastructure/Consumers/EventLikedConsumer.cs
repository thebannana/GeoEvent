using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventLikedConsumer : IConsumer<EventLikedMessage>
{
    private readonly INotificationService _notificationService;

    public EventLikedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventLikedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventLiked,
            Title = $"{message.LikedByDisplayName} liked your event",
            Description = $"Your event '{message.EventTitle}' got a new like.",
            ImageUrl = message.EventImageUrl
        });
    }
}