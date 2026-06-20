using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Users;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class UserBannedNotificationConsumer : IConsumer<UserBannedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public UserBannedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<UserBannedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.AccountBanned,
            Title = "Account Suspended",
            Description = $"Your account has been suspended. Reason: {message.Reason}"
        }, context.CancellationToken);
    }
}