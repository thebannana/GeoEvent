using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventCancelledConsumer : IConsumer<EventCancelledMessage>
{
    private readonly INotificationService _notificationService;

    public EventCancelledConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<EventCancelledMessage> context)
    {
        var msg = context.Message;
        if (msg.OrganizerId is null) return;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.OrganizerId.Value,
            Type = NotificationType.EventCancelled,
            Title = "Event Cancelled",
            Description = $"Your event \"{msg.Title}\" has been cancelled. Reason: {msg.Reason}"
        });
    }
}
