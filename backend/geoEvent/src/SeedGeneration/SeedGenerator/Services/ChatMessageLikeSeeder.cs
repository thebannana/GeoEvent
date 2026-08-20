using MassTransit;
using MessageService.Domain.Entities;
using MessageService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class ChatMessageLikeSeeder : ISeeder
{
    private readonly MessageDbContext _dbContext;
    private readonly IReadOnlyList<SeedChatMessageLikeOptions> _likes;
    private readonly ILogger<ChatMessageLikeSeeder> _logger;

    public ChatMessageLikeSeeder(
        MessageDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<ChatMessageLikeSeeder> logger)
    {
        _dbContext = dbContext;
        _likes = options.Value.SeedChatMessageLikes ?? new List<SeedChatMessageLikeOptions>();
        _logger = logger;
    }

    public string Name => "chatmessagelikes";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_likes.Count == 0)
        {
            _logger.LogWarning("No chat message likes configured in SeedChatMessageLikes.");
            return;
        }

        foreach (var seed in _likes)
        {
            var messageExists = await _dbContext.ChatMessages.AnyAsync(m => m.Id == seed.MessageId, cancellationToken);
            if (!messageExists)
            {
                _logger.LogWarning("Skipping chat message like: MessageId {MessageId} does not exist.", seed.MessageId);
                continue;
            }

            var existing = await _dbContext.ChatMessageLikes
                .FirstOrDefaultAsync(l => l.MessageId == seed.MessageId && l.UserId == seed.UserId, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Chat message like already exists: MessageId {MessageId}, UserId {UserId}", seed.MessageId, seed.UserId);
                continue;
            }

            var like = new ChatMessageLike(seed.MessageId, seed.UserId);

            await _dbContext.ChatMessageLikes.AddAsync(like, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Chat message like created: MessageId {MessageId}, UserId {UserId}", like.MessageId, like.UserId);
        }
    }
}