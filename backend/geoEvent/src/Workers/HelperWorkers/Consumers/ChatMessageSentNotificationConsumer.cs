using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Chat;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ChatMessageSentNotificationConsumer : IConsumer<ChatMessageSentIntegrationEvent>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ChatMessageSentNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
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
                ? (message.IsGroupThread
                    ? $"{message.SenderDisplayName} sent a new message."
                    : "You received a new message.")
                : $"{message.SenderDisplayName}: {message.MessagePreview}";

            var imageUrl = message.IsGroupThread
                ? message.ThreadImageUrl
                : message.SenderAvatarUrl;

            await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
            {
                UserId = recipientUserId,
                Type = NotificationType.NewMessage,
                Title = title,
                Description = description,
                ImageUrl = imageUrl
            }, context.CancellationToken);
        }
    }
}