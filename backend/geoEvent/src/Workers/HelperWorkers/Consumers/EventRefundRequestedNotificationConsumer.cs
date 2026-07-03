using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class EventRefundRequestedNotificationConsumer : IConsumer<EventRefundRequestedMessage>
{
    private readonly INotificationApiClient notificationApiClient;

    public EventRefundRequestedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        this.notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<EventRefundRequestedMessage> context)
    {
        var message = context.Message;

        await notificationApiClient.CreateNotificationAsync(
            new CreateNotificationRequest
            {
                UserId = message.OrganizerUserId,
                Type = NotificationType.EventRefundRequested,
                Title = $"{message.RequestedByDisplayName} requested a refund",
                Description = string.IsNullOrWhiteSpace(message.RefundReason)
                    ? $"{message.EventTitle} · {message.Quantity} attendee(s) · {message.TotalAmount} {message.Currency}"
                    : $"{message.EventTitle} · {message.Quantity} attendee(s) · {message.TotalAmount} {message.Currency} · Reason: {message.RefundReason}",
                ImageUrl = message.RequestedByAvatarUrl ?? message.EventImageUrl
            },
            context.CancellationToken);
    }
}