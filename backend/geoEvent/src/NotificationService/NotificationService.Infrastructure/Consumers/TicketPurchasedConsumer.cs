using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class TicketPurchasedConsumer : IConsumer<TicketPurchasedMessage>
{
    private readonly INotificationService _notificationService;

    public TicketPurchasedConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<TicketPurchasedMessage> context)
    {
        var msg = context.Message;

        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = msg.UserId,
            Type = NotificationType.TicketPurchased,
            Title = "Ticket Confirmed",
            Description = $"Your {msg.TicketType} ticket has been issued. " +
                          $"Amount: {msg.Amount} {msg.Currency}."
        });
    }
}
