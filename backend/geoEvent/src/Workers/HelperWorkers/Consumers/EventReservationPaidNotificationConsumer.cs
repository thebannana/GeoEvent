using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventReservationPaidNotificationConsumer : IConsumer<EventReservationPaidMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventReservationPaidNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventReservationPaidMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerUserId,
            Type = NotificationType.EventReservationPaid,
            Title = $"{message.ReservedByDisplayName} completed payment",
            Description = $"{message.EventTitle} | {message.Quantity} attendees | {message.TotalAmount} {message.Currency} | {message.Status}",
            ImageUrl = message.ReservedByAvatarUrl ?? message.EventImageUrl
        }, context.CancellationToken);
    }
}