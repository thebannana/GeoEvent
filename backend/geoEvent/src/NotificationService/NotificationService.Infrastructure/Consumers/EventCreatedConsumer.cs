using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventCreatedConsumer : IConsumer<EventCreatedMessage>
{
    private readonly INotificationService _notificationService;

    public EventCreatedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<EventCreatedMessage> context)
    {
        var msg = context.Message;
        if (msg.OrganizerId is null) return;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.OrganizerId.Value,
            Type = NotificationType.EventCreated,
            Title = "Event Published",
            Description = $"Your event \"{msg.Title}\" is now live."
        });
    }
}
