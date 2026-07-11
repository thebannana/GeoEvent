using GeoEvent.HelperWorkers.Interfaces;
using MassTransit;
using Shared.Contracts.Events;

namespace GeoEvent.HelperWorkers.Consumers;

public sealed class UserEventPreferenceInteractionConsumer : IConsumer<UserEventPreferenceInteractionMessage>
{
    private readonly IUserPreferenceInternalClient _userPreferenceInternalClient;
    private readonly ILogger<UserEventPreferenceInteractionConsumer> _logger;

    public UserEventPreferenceInteractionConsumer(
        IUserPreferenceInternalClient userPreferenceInternalClient,
        ILogger<UserEventPreferenceInteractionConsumer> logger)
    {
        _userPreferenceInternalClient = userPreferenceInternalClient;
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

        await _userPreferenceInternalClient.ApplyInteractionPreferenceAsync(
            message,
            context.CancellationToken);
    }
}