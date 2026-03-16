using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Events;

namespace NotificationService.Infrastructure.Consumers;

public class EventStartingSoonConsumer : IConsumer<EventStartingSoonMessage>
{
    private readonly INotificationService _notificationService;

    public EventStartingSoonConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<EventStartingSoonMessage> context)
    {
        var msg = context.Message;

        // UserId = 0 signals the processor to fan-out to all attendees
        await _notificationService.QueueNotificationAsync(new QueueNotificationDto
        {
            UserId = 0,
            Type = NotificationType.EventStartingSoon,
            Payload = $"{{\"eventId\":{msg.EventId},\"title\":\"{msg.Title}\"," +
                      $"\"startDateTime\":\"{msg.StartDateTime:O}\"}}",
            ScheduledAt = DateTime.UtcNow
        });
    }

}
