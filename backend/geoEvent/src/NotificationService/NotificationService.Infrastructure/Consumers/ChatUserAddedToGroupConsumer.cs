using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Chat;

namespace NotificationService.Infrastructure.Consumers;

public class ChatUserAddedToGroupConsumer : IConsumer<ChatUserAddedToGroupIntegrationEvent>
{
    private readonly INotificationService _notificationService;

    public ChatUserAddedToGroupConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<ChatUserAddedToGroupIntegrationEvent> context)
    {
        var message = context.Message;

        var description = string.IsNullOrWhiteSpace(message.AddedByDisplayName)
            ? $"You were added to a group '{message.GroupTitle}'."
            : $"You were added to a group '{message.GroupTitle}' by {message.AddedByDisplayName}.";

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.AddedUserId,
            Type = NotificationType.GroupAdded,
            Title = $"Added to {message.GroupTitle}",
            Description = description,
            ImageUrl = message.GroupImageUrl
        });
    }
}