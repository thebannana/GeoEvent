using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class ReservationRefundApprovedNotificationConsumer : IConsumer<ReservationRefundApprovedMessage>
{
    private readonly INotificationApiClient notificationApiClient;

    public ReservationRefundApprovedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        this.notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<ReservationRefundApprovedMessage> context)
    {
        var message = context.Message;

        await notificationApiClient.CreateNotificationAsync(
            new CreateNotificationRequest
            {
                UserId = message.UserId,
                Type = NotificationType.ReservationRefundApproved,
                Title = "Refund approved",
                Description = string.IsNullOrWhiteSpace(message.DecisionReason)
                    ? $"Your refund for {message.EventTitle} was approved. Amount: {message.RefundedAmount} {message.Currency}."
                    : $"Your refund for {message.EventTitle} was approved. Amount: {message.RefundedAmount} {message.Currency}. Reason: {message.DecisionReason}",
                ImageUrl = message.EventImageUrl
            },
            context.CancellationToken);
    }
}