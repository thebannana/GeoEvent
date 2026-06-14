using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Chat;

namespace NotificationService.Infrastructure.Consumers;

public class ChatMessageLikedConsumer : IConsumer<ChatMessageLikedIntegrationEvent>
{
    private readonly INotificationService _notificationService;

    public ChatMessageLikedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<ChatMessageLikedIntegrationEvent> context)
    {
        var message = context.Message;

        if (message.MessageOwnerUserId == message.LikedByUserId)
            return;

        var description = string.IsNullOrWhiteSpace(message.MessagePreview)
            ? $"{message.LikedByDisplayName} liked your message."
            : $"{message.LikedByDisplayName} liked your message: \"{message.MessagePreview}\"";

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.MessageOwnerUserId,
            Type = NotificationType.MessageLiked,
            Title = $"Your message got a like from {message.LikedByDisplayName}",
            Description = description,
            ImageUrl = message.LikedByAvatarUrl
        });
    }
}