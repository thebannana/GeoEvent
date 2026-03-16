using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class PaymentSucceededConsumer : IConsumer<PaymentSucceededMessage>
{
    private readonly INotificationService _notificationService;

    public PaymentSucceededConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<PaymentSucceededMessage> context)
    {
        var msg = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.PaymentSucceeded,
            Title = "Payment Successful",
            Description = $"Payment of {msg.Amount} {msg.Currency} confirmed. " +
                          $"Transaction: {msg.TransactionId}"
        });
    }
}
