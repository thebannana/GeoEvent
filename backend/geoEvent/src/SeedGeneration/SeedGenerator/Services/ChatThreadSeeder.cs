using MassTransit;
using MessageService.Domain.Entities;
using MessageService.Domain.Enums;
using MessageService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class ChatThreadSeeder : ISeeder
{
    private readonly MessageDbContext _dbContext;
    private readonly IReadOnlyList<SeedChatThreadOptions> _threads;
    private readonly ILogger<ChatThreadSeeder> _logger;

    public ChatThreadSeeder(
        MessageDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<ChatThreadSeeder> logger)
    {
        _dbContext = dbContext;
        _threads = options.Value.SeedChatThreads ?? new List<SeedChatThreadOptions>();
        _logger = logger;
    }

    public string Name => "chatthreads";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_threads.Count == 0)
        {
            _logger.LogWarning("No chat threads configured in SeedChatThreads.");
            return;
        }

        foreach (var seed in _threads)
        {
            if (!Enum.TryParse<ChatThreadType>(seed.Type, true, out var type))
            {
                _logger.LogWarning("Skipping chat thread: Invalid Type {Type}.", seed.Type);
                continue;
            }

            if (type == ChatThreadType.EventGroup && !seed.EventId.HasValue)
            {
                _logger.LogWarning("Skipping chat thread: EventGroup threads must have an EventId.");
                continue;
            }

            if (seed.ParticipantUserIds.Count < 2 && type == ChatThreadType.Direct)
            {
                _logger.LogWarning("Skipping chat thread: Direct threads must have at least 2 participants.");
                continue;
            }

            ChatThread? existing = null;
            if (type == ChatThreadType.Direct && seed.ParticipantUserIds.Count == 2)
            {
                var u1 = seed.ParticipantUserIds[0];
                var u2 = seed.ParticipantUserIds[1];
                existing = await _dbContext.ChatThreads
                    .Include(t => t.Participants)
                    .FirstOrDefaultAsync(t =>
                        t.Type == ChatThreadType.Direct &&
                        t.Participants.Count == 2 &&
                        t.Participants.Any(p => p.UserId == u1) &&
                        t.Participants.Any(p => p.UserId == u2),
                        cancellationToken);
            }

            if (existing is not null)
            {
                _logger.LogInformation("Chat thread already exists: ThreadId {ThreadId}", existing.Id);
                continue;
            }

            var thread = new ChatThread(
                type,
                type == ChatThreadType.Direct ? string.Empty : seed.Title.Trim(),
                seed.CreatedByUserId,
                seed.EventId);

            await _dbContext.ChatThreads.AddAsync(thread, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            foreach (var userId in seed.ParticipantUserIds)
            {
                var participant = new ChatThreadParticipant(thread.Id, userId);
                await _dbContext.ChatThreadParticipants.AddAsync(participant, cancellationToken);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Chat thread created: ThreadId {ThreadId}, Type {Type}", thread.Id, thread.Type);
        }
    }
}