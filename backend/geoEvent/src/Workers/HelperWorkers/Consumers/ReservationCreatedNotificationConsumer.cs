using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ReservationCreatedNotificationConsumer : IConsumer<ReservationCreatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ReservationCreatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.ReservationConfirmed,
            Title = "Reservation Created",
            Description = $"Your reservation for {message.Quantity}x {message.TicketType} is held until {message.ExpiresAt:HH:mm} UTC. Complete payment to confirm."
        }, context.CancellationToken);
    }
}