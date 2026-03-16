using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class ReservationCreatedConsumer : IConsumer<ReservationCreatedMessage>
{
    private readonly INotificationService _notificationService;

    public ReservationCreatedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<ReservationCreatedMessage> context)
    {
        var msg = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.ReservationConfirmed,
            Title = "Reservation Created",
            Description = $"Your reservation for {msg.Quantity}x {msg.TicketType} " +
                          $"is held until {msg.ExpiresAt:HH:mm} UTC. Complete payment to confirm."
        });
    }
}
