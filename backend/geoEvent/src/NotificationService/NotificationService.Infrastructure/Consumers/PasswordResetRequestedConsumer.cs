using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Users;

namespace NotificationService.Infrastructure.Consumers;

public class PasswordResetRequestedConsumer : IConsumer<PasswordResetRequestedMessage>
{
    private readonly INotificationService _notificationService;

    public PasswordResetRequestedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<PasswordResetRequestedMessage> context)
    {
        var msg = context.Message;

        await _notificationService.QueueNotificationAsync(new QueueNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.PasswordReset,
            Payload = $"{{\"email\":\"{msg.Email}\",\"token\":\"{msg.Token}\"}}",
            ScheduledAt = DateTime.UtcNow
        });
    }
}
