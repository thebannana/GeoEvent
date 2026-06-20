using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Chat;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ChatUserAddedToGroupNotificationConsumer : IConsumer<ChatUserAddedToGroupIntegrationEvent>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ChatUserAddedToGroupNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ChatUserAddedToGroupIntegrationEvent> context)
    {
        var message = context.Message;

        var description = string.IsNullOrWhiteSpace(message.AddedByDisplayName)
            ? $"You were added to a group: {message.GroupTitle}."
            : $"You were added to a group: {message.GroupTitle} by {message.AddedByDisplayName}.";

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.AddedUserId,
            Type = NotificationType.GroupAdded,
            Title = $"Added to {message.GroupTitle}",
            Description = description,
            ImageUrl = message.GroupImageUrl
        }, context.CancellationToken);
    }
}