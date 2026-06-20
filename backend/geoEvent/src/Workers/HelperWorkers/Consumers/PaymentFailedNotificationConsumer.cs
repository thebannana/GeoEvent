using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class PaymentFailedNotificationConsumer : IConsumer<PaymentFailedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public PaymentFailedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<PaymentFailedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.PaymentFailed,
            Title = "Payment Failed",
            Description = $"Your payment of {message.Amount} {message.Currency} could not be processed. Reason: {message.FailureReason}"
        }, context.CancellationToken);
    }
}