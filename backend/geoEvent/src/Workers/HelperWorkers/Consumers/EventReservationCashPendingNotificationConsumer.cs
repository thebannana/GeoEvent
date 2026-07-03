using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventReservationCashPendingNotificationConsumer : IConsumer<EventReservationCashPendingMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventReservationCashPendingNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventReservationCashPendingMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerUserId,
            Type = NotificationType.EventReservationCashPending,
            Title = "Cash Reservation Confirmed",
            Description =
                $"{message.AttendeeDisplayName} confirmed a reservation for {message.Quantity} ticket(s) and owes {message.Amount} {message.Currency} in cash at the event."
        }, context.CancellationToken);
    }
}