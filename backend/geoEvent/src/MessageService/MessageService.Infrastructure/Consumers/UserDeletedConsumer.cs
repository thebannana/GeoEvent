using MassTransit;
using MessageService.Application.Interfaces.Services;
using Shared.Contracts.Users;

namespace MessageService.Infrastructure.Consumers;

public class UserDeletedConsumer : IConsumer<UserDeletedMessage>
{
    private readonly IMessageService _messageService;

    public UserDeletedConsumer(IMessageService messageService)
        => _messageService = messageService;

    public async Task Consume(ConsumeContext<UserDeletedMessage> context)
    {
        await _messageService.SoftDeleteUserMessagesAsync(context.Message.UserId);
    }
}
