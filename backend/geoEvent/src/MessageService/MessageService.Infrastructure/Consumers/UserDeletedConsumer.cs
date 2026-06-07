using MassTransit;
using MessageService.Application.Interfaces.Services;
using Shared.Contracts.Users;

namespace MessageService.Infrastructure.Consumers;

public class UserDeletedConsumer : IConsumer<UserDeletedMessage>
{
    private readonly IChatService _chatService;

    public UserDeletedConsumer(IChatService chatService)
    {
        _chatService = chatService;
    }

    public async Task Consume(ConsumeContext<UserDeletedMessage> context)
    {
        await _chatService.HandleDeletedUserAsync(context.Message.UserId);
    }
}