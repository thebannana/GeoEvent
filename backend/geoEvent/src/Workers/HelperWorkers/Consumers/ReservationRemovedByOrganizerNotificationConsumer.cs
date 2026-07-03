using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ReservationRemovedByOrganizerNotificationConsumer : IConsumer<ReservationRemovedByOrganizerMessage>
{
    private readonly INotificationApiClient notificationApiClient;

    public ReservationRemovedByOrganizerNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        this.notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationRemovedByOrganizerMessage> context)
    {
        var message = context.Message;

        await notificationApiClient.CreateNotificationAsync(
            new CreateNotificationRequest
            {
                UserId = message.UserId,
                Type = NotificationType.ReservationRemovedByOrganizer,
                Title = "Reservation removed",
                Description = $"Your reservation for {message.EventTitle} was removed by the organizer.",
                ImageUrl = message.EventImageUrl
            },
            context.CancellationToken);
    }
}