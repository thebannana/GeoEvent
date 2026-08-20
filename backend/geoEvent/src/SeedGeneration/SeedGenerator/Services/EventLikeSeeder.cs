using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class EventLikeSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedEventLikeOptions> _likes;
    private readonly ILogger<EventLikeSeeder> _logger;

    public EventLikeSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<EventLikeSeeder> logger)
    {
        _dbContext = dbContext;
        _likes = options.Value.SeedEventLikes ?? new List<SeedEventLikeOptions>();
        _logger = logger;
    }

    public string Name => "eventlikes";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_likes.Count == 0)
        {
            _logger.LogWarning("No event likes configured in SeedEventLikes.");
            return;
        }

        foreach (var seed in _likes)
        {
            var eventExists = await _dbContext.Events.AnyAsync(e => e.EventId == seed.EventId, cancellationToken);
            if (!eventExists)
            {
                _logger.LogWarning("Skipping event like: EventId {EventId} does not exist.", seed.EventId);
                continue;
            }

            var existing = await _dbContext.EventLikes
                .FirstOrDefaultAsync(l => l.EventId == seed.EventId && l.UserId == seed.UserId, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Event like already exists: EventId {EventId}, UserId {UserId}", seed.EventId, seed.UserId);
                continue;
            }

            var like = new EventLike(seed.EventId, seed.UserId);

            await _dbContext.EventLikes.AddAsync(like, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Event like created: EventId {EventId}, UserId {UserId}", like.EventId, like.UserId);
        }
    }
}