using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

/// <summary>
/// Creates the in-app notification for the event organizer when an attendee
/// cancels their reservation.
/// </summary>
public class ReservationCancelledNotificationConsumer : IConsumer<ReservationCancelledMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public ReservationCancelledNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationCancelledMessage> context)
    {
        var message = context.Message;

        // Nobody to notify (organizer unknown, or the organizer cancelled their own reservation).
        if (message.OrganizerUserId is not int organizerUserId || organizerUserId == message.UserId)
            return;

        var who = string.IsNullOrWhiteSpace(message.CancelledByDisplayName)
            ? "An attendee"
            : message.CancelledByDisplayName;

        var eventTitle = string.IsNullOrWhiteSpace(message.EventTitle)
            ? $"Event #{message.EventId}"
            : message.EventTitle;

        var reason = string.IsNullOrWhiteSpace(message.CancellationReason)
            ? "No reason provided"
            : message.CancellationReason;

        var quantity = message.Quantity > 0 ? $" | {message.Quantity} attendees" : string.Empty;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = organizerUserId,
            Type = NotificationType.EventReservationCancelled,
            Title = $"{who} cancelled a reservation",
            Description = $"{eventTitle}{quantity} | Reason: {reason}",
            ImageUrl = message.CancelledByAvatarUrl ?? message.EventImageUrl
        }, context.CancellationToken);
    }
}
