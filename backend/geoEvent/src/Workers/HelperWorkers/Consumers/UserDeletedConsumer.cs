using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Users;

namespace GeoEvent.HelperWorkers.Consumers.Messages;

public class UserDeletedConsumer : IConsumer<UserDeletedMessage>
{
    private readonly IMessageChatAdminClient _chatAdminClient;

    public UserDeletedConsumer(IMessageChatAdminClient chatAdminClient)
    {
        _chatAdminClient = chatAdminClient;
    }

    public async Task Consume(ConsumeContext<UserDeletedMessage> context)
    {
        await _chatAdminClient.HandleDeletedUserAsync(context.Message.UserId);
    }
}