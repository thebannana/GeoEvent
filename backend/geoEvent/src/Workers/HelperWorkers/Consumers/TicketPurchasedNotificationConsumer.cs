using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Enums;
using Shared.Contracts.Tickets;

namespace GeoEvent.HelperWorkers.Consumers.Notifications;

public class TicketPurchasedNotificationConsumer : IConsumer<TicketPurchasedMessage>
{
    private readonly INotificationApiClient _notificationApiClient;

    public TicketPurchasedNotificationConsumer(INotificationApiClient notificationApiClient)
    {
        _notificationApiClient = notificationApiClient;
    }

    public async Task Consume(ConsumeContext<TicketPurchasedMessage> context)
    {
        var message = context.Message;

        await _notificationApiClient.CreateNotificationAsync(new CreateNotificationRequest
        {
            UserId = message.UserId,
            Type = NotificationType.TicketPurchased,
            Title = "Ticket Confirmed",
            Description = $"Your {message.TicketType} ticket has been issued. Amount: {message.Amount} {message.Currency}."
        }, context.CancellationToken);
    }
}