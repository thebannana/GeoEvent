using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Users;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class PasswordResetRequestedNotificationConsumer : IConsumer<PasswordResetRequestedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public PasswordResetRequestedNotificationConsumer(
        INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<PasswordResetRequestedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(
            new CreateNotificationRequest
            {
                UserId = message.UserId,
                Type = NotificationType.PasswordReset,
                Title = "Password Reset Requested",
                Description = $"A password reset was requested for {message.Email}."
            },
            context.CancellationToken);
    }
}