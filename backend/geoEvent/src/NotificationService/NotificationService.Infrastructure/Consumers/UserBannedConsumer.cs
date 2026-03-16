using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Users;

namespace NotificationService.Infrastructure.Consumers;

public class UserBannedConsumer : IConsumer<UserBannedMessage>
{
    private readonly INotificationService _notificationService;

    public UserBannedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<UserBannedMessage> context)
    {
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = context.Message.UserId,
            Type = NotificationType.AccountBanned,
            Title = "Account Suspended",
            Description = $"Your account has been suspended. Reason: {context.Message.Reason}"
        });
    }
}
