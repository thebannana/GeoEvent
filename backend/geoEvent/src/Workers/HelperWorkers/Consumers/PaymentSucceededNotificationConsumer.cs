using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class PaymentSucceededNotificationConsumer : IConsumer<PaymentSucceededMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public PaymentSucceededNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<PaymentSucceededMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.PaymentSucceeded,
            Title = "Payment Successful",
            Description = $"Payment of {message.Amount} {message.Currency} confirmed. Transaction: {message.TransactionId}"
        }, context.CancellationToken);
    }
}