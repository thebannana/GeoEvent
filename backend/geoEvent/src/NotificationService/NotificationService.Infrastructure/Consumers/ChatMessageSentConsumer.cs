using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Chat;

namespace NotificationService.Infrastructure.Consumers;

public class ChatMessageSentConsumer : IConsumer<ChatMessageSentIntegrationEvent>
{
    private readonly INotificationService _notificationService;

    public ChatMessageSentConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<ChatMessageSentIntegrationEvent> context)
    {
        var message = context.Message;

        foreach (var recipientUserId in message.RecipientUserIds.Distinct())
        {
            var title = message.IsGroupThread
                ? $"New message in {message.ThreadTitle}"
                : $"New message from {message.SenderDisplayName}";

            var description = string.IsNullOrWhiteSpace(message.MessagePreview)
                ? message.IsGroupThread
                    ? $"{message.SenderDisplayName} sent a new message."
                    : "You received a new message."
                : $"{message.SenderDisplayName}: {message.MessagePreview}";

            var imageUrl = message.IsGroupThread
                ? message.ThreadImageUrl
                : message.SenderAvatarUrl;

            await _notificationService.CreateNotificationAsync(new CreateNotificationDto
            {
                UserId = recipientUserId,
                Type = NotificationType.NewMessage,
                Title = title,
                Description = description,
                ImageUrl = imageUrl
            });
        }
    }
}