using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Users;

namespace NotificationService.Infrastructure.Consumers;

public class UserRegisteredConsumer : IConsumer<UserRegisteredMessage>
{
    private readonly INotificationService _notificationService;

    public UserRegisteredConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<UserRegisteredMessage> context)
    {
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = context.Message.UserId,
            Type = NotificationType.Welcome,
            Title = "Welcome to GeoEvent!",
            Description = $"Hey {context.Message.FirstName}, your account is ready to go."
        });
    }
}
