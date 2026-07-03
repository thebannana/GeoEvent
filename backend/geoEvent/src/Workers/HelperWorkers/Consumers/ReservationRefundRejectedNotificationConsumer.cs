using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ReservationRefundRejectedNotificationConsumer : IConsumer<ReservationRefundRejectedMessage>
{
    private readonly INotificationApiClient notificationApiClient;

    public ReservationRefundRejectedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        this.notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationRefundRejectedMessage> context)
    {
        var message = context.Message;

        await notificationApiClient.CreateNotificationAsync(
            new CreateNotificationRequest
            {
                UserId = message.UserId,
                Type = NotificationType.ReservationRefundRejected,
                Title = "Refund rejected",
                Description = string.IsNullOrWhiteSpace(message.DecisionReason)
                    ? $"Your refund request for {message.EventTitle} was rejected."
                    : $"Your refund request for {message.EventTitle} was rejected. Reason: {message.DecisionReason}",
                ImageUrl = message.EventImageUrl
            },
            context.CancellationToken);
    }
}