using MassTransit;
using Shared.Contracts.Events;
using UserService.Application.Interfaces.Services;

namespace UserService.Infrastructure.Consumers;

public class UserEventPreferenceInteractionConsumer : IConsumer<UserEventPreferenceInteractionMessage>
{
    private readonly IUserService userService;

    public UserEventPreferenceInteractionConsumer(IUserService userService)
    {
        this.userService = userService;
    }

    public async Task Consume(ConsumeContext<UserEventPreferenceInteractionMessage> context)
    {
        var message = context.Message;

        await userService.ApplyInteractionPreferenceAsync(
            message.UserId,
            message.EventId,
            message.SegmentId,
            message.GenreId,
            message.SubGenreId,
            message.InteractionType,
            message.OccurredAt);
    }
}