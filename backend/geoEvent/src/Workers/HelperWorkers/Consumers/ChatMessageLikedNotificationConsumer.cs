using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Chat;
using Shared.Contracts.Enums;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ChatMessageLikedNotificationConsumer : IConsumer<ChatMessageLikedIntegrationEvent>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ChatMessageLikedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ChatMessageLikedIntegrationEvent> context)
    {
        var message = context.Message;

        if (message.MessageOwnerUserId == message.LikedByUserId)
            return;

        var description = string.IsNullOrWhiteSpace(message.MessagePreview)
            ? $"{message.LikedByDisplayName} liked your message."
            : $"{message.LikedByDisplayName} liked your message: {message.MessagePreview}";

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.MessageOwnerUserId,
            Type = NotificationType.MessageLiked,
            Title = $"Your message got a like from {message.LikedByDisplayName}",
            Description = description,
            ImageUrl = message.LikedByAvatarUrl
        }, context.CancellationToken);
    }
}