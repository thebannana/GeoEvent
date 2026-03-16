using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class PaymentFailedConsumer : IConsumer<PaymentFailedMessage>
{
    private readonly INotificationService _notificationService;

    public PaymentFailedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<PaymentFailedMessage> context)
    {
        var msg = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.PaymentFailed,
            Title = "Payment Failed",
            Description = $"Your payment of {msg.Amount} {msg.Currency} could not be processed. " +
                          $"Reason: {msg.FailureReason}"
        });
    }
}
