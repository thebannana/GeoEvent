using MassTransit;
using MessageService.Application.Interfaces.Services;
using Shared.Contracts.Reservations;

namespace MessageService.Infrastructure.Consumers;

public class ReservationCancelledIntegrationConsumer : IConsumer<ReservationCancelledIntegrationMessage>
{
    private readonly IChatService _chatService;

    public ReservationCancelledIntegrationConsumer(IChatService chatService)
    {
        _chatService = chatService;
    }

    public async Task Consume(ConsumeContext<ReservationCancelledIntegrationMessage> context)
    {
        await _chatService.RemoveUserFromEventThreadAsync(
            context.Message.EventId,
            context.Message.UserId);
    }
}