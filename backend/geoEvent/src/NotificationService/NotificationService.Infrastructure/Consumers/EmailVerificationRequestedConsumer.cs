using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Users;

namespace NotificationService.Infrastructure.Consumers;

public class EmailVerificationRequestedConsumer : IConsumer<EmailVerificationRequestedMessage>
{
    private readonly INotificationService _notificationService;

    public EmailVerificationRequestedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<EmailVerificationRequestedMessage> context)
    {
        var msg = context.Message;

        // Queue for actual email dispatch
        await _notificationService.QueueNotificationAsync(new QueueNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.EmailVerification,
            Payload = $"{{\"email\":\"{msg.Email}\",\"token\":\"{msg.Token}\"}}",
            ScheduledAt = DateTime.UtcNow
        });
    }
}
