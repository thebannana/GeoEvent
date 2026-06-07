using MassTransit;
using MessageService.Application.Interfaces.Services;
using Shared.Contracts.Reservations;

namespace MessageService.Infrastructure.Consumers;

public class ReservationConfirmedConsumer : IConsumer<ReservationConfirmedMessage>
{
    private readonly IChatService _chatService;

    public ReservationConfirmedConsumer(IChatService chatService)
    {
        _chatService = chatService;
    }

    public async Task Consume(ConsumeContext<ReservationConfirmedMessage> context)
    {
        await _chatService.AddUserToEventThreadAsync(
            context.Message.EventId,
            context.Message.UserId);
    }
}