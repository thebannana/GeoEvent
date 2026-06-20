using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Reservations;

namespace GeoEvent.HelperWorkers.Consumers.Messages;

public class ReservationConfirmedConsumer : IConsumer<ReservationConfirmedMessage>
{
    private readonly IMessageChatAdminClient _chatAdminClient;

    public ReservationConfirmedConsumer(IMessageChatAdminClient chatAdminClient)
    {
        _chatAdminClient = chatAdminClient;
    }

    public async Task Consume(ConsumeContext<ReservationConfirmedMessage> context)
    {
        await _chatAdminClient.AddUserToEventThreadAsync(
            context.Message.EventId,
            context.Message.UserId);
    }
}