using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventReservationCreatedNotificationConsumer : IConsumer<EventReservationCreatedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public EventReservationCreatedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventReservationCreatedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.OrganizerUserId,
            Type = NotificationType.EventReservationCreated,
            Title = $"{message.ReservedByDisplayName} reserved your event",
            Description = $"{message.EventTitle} | {message.Quantity} attendees | {message.TotalAmount} {message.Currency} | {message.Status}",
            ImageUrl = message.ReservedByAvatarUrl ?? message.EventImageUrl
        }, context.CancellationToken);
    }
}