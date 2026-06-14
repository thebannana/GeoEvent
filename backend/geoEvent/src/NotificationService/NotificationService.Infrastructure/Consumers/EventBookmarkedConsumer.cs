using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventBookmarkedConsumer : IConsumer<EventBookmarkedMessage>
{
    private readonly INotificationService _notificationService;

    public EventBookmarkedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventBookmarkedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventBookmarked,
            Title = $"{message.BookmarkedByDisplayName} saved your event",
            Description = $"Your event '{message.EventTitle}' was bookmarked.",
            ImageUrl = message.EventImageUrl
        });
    }
}