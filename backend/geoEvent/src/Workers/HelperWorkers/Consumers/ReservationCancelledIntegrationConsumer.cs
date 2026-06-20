using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Messages;

public class ReservationCancelledIntegrationConsumer : IConsumer<ReservationCancelledIntegrationMessage>
{
    private readonly IMessageChatAdminClient _chatAdminClient;

    public ReservationCancelledIntegrationConsumer(IMessageChatAdminClient chatAdminClient)
    {
        _chatAdminClient = chatAdminClient;
    }

    public async Task Consume(ConsumeContext<ReservationCancelledIntegrationMessage> context)
    {
        await _chatAdminClient.RemoveUserFromEventThreadAsync(
            context.Message.EventId,
            context.Message.UserId);
    }
}