using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Reservations;

namespace NotificationService.Infrastructure.Consumers;

public class EventReservationPaidConsumer : IConsumer<EventReservationPaidMessage>
{
    private readonly INotificationService _notificationService;

    public EventReservationPaidConsumer(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    public async Task Consume(ConsumeContext<EventReservationPaidMessage> context)
    {
        var message = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = message.OrganizerUserId,
            Type = NotificationType.EventReservationPaid,
            Title = $"{message.ReservedByDisplayName} completed payment",
            Description = $"{message.EventTitle} • {message.Quantity} attendee(s) • {message.TotalAmount} {message.Currency} • {message.Status}",
            ImageUrl = message.ReservedByAvatarUrl ?? message.EventImageUrl
        });
    }
}