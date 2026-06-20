using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventBookmarkedNotificationConsumer : IConsumer<EventBookmarkedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventBookmarkedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventBookmarkedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.EventOwnerUserId,
            Type = NotificationType.EventBookmarked,
            Title = $"{message.BookmarkedByDisplayName} saved your event",
            Description = $"Your event {message.EventTitle} was bookmarked.",
            ImageUrl = message.EventImageUrl
        }, context.CancellationToken);
    }
}