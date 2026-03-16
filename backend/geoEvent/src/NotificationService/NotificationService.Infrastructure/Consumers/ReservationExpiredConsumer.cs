using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class ReservationExpiredConsumer : IConsumer<ReservationExpiredMessage>
{
    private readonly INotificationService _notificationService;

    public ReservationExpiredConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<ReservationExpiredMessage> context)
    {
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = context.Message.UserId,
            Type = NotificationType.ReservationExpired,
            Title = "Reservation Expired",
            Description = "Your reservation has expired and your held tickets have been released."
        });
    }
}
