using MassTransit;
using Shared.Contracts.Events;
using UserService.Application.Interfaces.Services;

namespace GeoEvent.HelperWorkers.Consumers;

public class UserEventPreferenceInteractionConsumer : IConsumer<UserEventPreferenceInteractionMessage>
{
    private readonly IUserService _userService;
    private readonly ILogger<UserEventPreferenceInteractionConsumer> _logger;

    public UserEventPreferenceInteractionConsumer(
        IUserService userService,
        ILogger<UserEventPreferenceInteractionConsumer> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<UserEventPreferenceInteractionMessage> context)
    {
        var message = context.Message;

        _logger.LogInformation(
            "Processing UserEventPreferenceInteractionMessage for UserId {UserId}, EventId {EventId}, InteractionType {InteractionType}",
            message.UserId,
            message.EventId,
            message.InteractionType);

        await _userService.ApplyInteractionPreferenceAsync(
            message.UserId,
            message.EventId,
            message.SegmentId,
            message.GenreId,
            message.SubGenreId,
            message.InteractionType,
            message.OccurredAt);
    }
}