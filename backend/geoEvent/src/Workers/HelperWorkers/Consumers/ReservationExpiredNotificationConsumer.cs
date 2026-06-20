using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ReservationExpiredNotificationConsumer : IConsumer<ReservationExpiredMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ReservationExpiredNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationExpiredMessage> context)
    {
        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = context.Message.UserId,
            Type = NotificationType.ReservationExpired,
            Title = "Reservation Expired",
            Description = "Your reservation has expired and your held tickets have been released."
        }, context.CancellationToken);
    }
}