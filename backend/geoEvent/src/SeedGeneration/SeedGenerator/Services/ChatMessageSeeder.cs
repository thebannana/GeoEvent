using MassTransit;
using MessageService.Domain.Entities;
using MessageService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class ChatMessageSeeder : ISeeder
{
    private readonly MessageDbContext _dbContext;
    private readonly IReadOnlyList<SeedChatMessageOptions> _messages;
    private readonly ILogger<ChatMessageSeeder> _logger;

    public ChatMessageSeeder(
        MessageDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<ChatMessageSeeder> logger)
    {
        _dbContext = dbContext;
        _messages = options.Value.SeedChatMessages ?? new List<SeedChatMessageOptions>();
        _logger = logger;
    }

    public string Name => "chatmessages";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_messages.Count == 0)
        {
            _logger.LogWarning("No chat messages configured in SeedChatMessages.");
            return;
        }

        foreach (var seed in _messages)
        {
            var threadExists = await _dbContext.ChatThreads.AnyAsync(t => t.Id == seed.ThreadId, cancellationToken);
            if (!threadExists)
            {
                _logger.LogWarning("Skipping chat message: ThreadId {ThreadId} does not exist.", seed.ThreadId);
                continue;
            }

            ChatMessage? replyTo = null;
            if (seed.ReplyToMessageId.HasValue)
            {
                replyTo = await _dbContext.ChatMessages
                    .FirstOrDefaultAsync(m => m.Id == seed.ReplyToMessageId.Value, cancellationToken);

                if (replyTo is null || replyTo.ThreadId != seed.ThreadId)
                {
                    _logger.LogWarning("Skipping chat message: ReplyToMessageId {ReplyId} is invalid.", seed.ReplyToMessageId.Value);
                    continue;
                }
            }

            var message = new ChatMessage(
                seed.ThreadId,
                seed.SenderId,
                seed.Content.Trim(),
                seed.ReplyToMessageId);

            await _dbContext.ChatMessages.AddAsync(message, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Chat message created: MessageId {MessageId}, ThreadId {ThreadId}", message.Id, message.ThreadId);
        }
    }
}