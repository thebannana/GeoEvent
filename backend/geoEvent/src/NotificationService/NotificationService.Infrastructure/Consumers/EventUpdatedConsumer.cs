using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventUpdatedConsumer : IConsumer<EventUpdatedMessage>
{
    private readonly INotificationService _notificationService;

    public EventUpdatedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<EventUpdatedMessage> context)
    {
        var msg = context.Message;
        if (msg.OrganizerId is null) return;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.OrganizerId.Value,
            Type = NotificationType.EventUpdated,
            Title = "Event Updated",
            Description = $"\"{msg.Title}\" has been updated."
                + (msg.ChangeSummary is not null ? $" {msg.ChangeSummary}" : string.Empty)
        });
    }
}
