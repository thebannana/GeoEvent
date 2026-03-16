using MassTransit;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Enums;
using Shared.Contracts.Tickets;

namespace NotificationService.Infrastructure.Consumers;

public class TicketCancelledConsumer : IConsumer<TicketCancelledMessage>
{
    private readonly INotificationService _notificationService;

    public TicketCancelledConsumer(INotificationService notificationService)
        => _notificationService = notificationService;

    public async Task Consume(ConsumeContext<TicketCancelledMessage> context)
    {
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = context.Message.UserId,
            Type = NotificationType.TicketCancelled,
            Title = "Ticket Cancelled",
            Description = $"Your ticket has been cancelled. Reason: {context.Message.Reason}"
        });
    }
}
