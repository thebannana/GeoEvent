using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Users;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class UserRegisteredNotificationConsumer : IConsumer<UserRegisteredMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public UserRegisteredNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<UserRegisteredMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.Welcome,
            Title = "Welcome to GeoEvent!",
            Description = $"Hey {message.FirstName}, your account is ready to go."
        }, context.CancellationToken);
    }
}