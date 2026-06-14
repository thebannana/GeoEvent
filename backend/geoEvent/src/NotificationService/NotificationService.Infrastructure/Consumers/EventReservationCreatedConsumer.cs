using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Reservations;

namespace NotificationService.Infrastructure.Consumers;

public class EventReservationCreatedConsumer : IConsumer<EventReservationCreatedMessage>
{
    private readonly INotificationService _notificationService;

    public EventReservationCreatedConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventReservationCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.OrganizerUserId,
            Type = NotificationType.EventReservationCreated,
            Title = $"{message.ReservedByDisplayName} reserved your event",
            Description = $"{message.EventTitle} • {message.Quantity} attendee(s) • {message.TotalAmount} {message.Currency} • {message.Status}",
            ImageUrl = message.ReservedByAvatarUrl ?? message.EventImageUrl
        });
    }
}