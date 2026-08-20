using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class EventImageSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedEventImageOptions> _images;
    private readonly ILogger<EventImageSeeder> _logger;

    public EventImageSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<EventImageSeeder> logger)
    {
        _dbContext = dbContext;
        _images = options.Value.SeedEventImages ?? new List<SeedEventImageOptions>();
        _logger = logger;
    }

    public string Name => "eventimages";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_images.Count == 0)
        {
            _logger.LogWarning("No event images configured in SeedEventImages.");
            return;
        }

        foreach (var seed in _images)
        {
            var eventExists = await _dbContext.Events.AnyAsync(e => e.EventId == seed.EventId, cancellationToken);
            if (!eventExists)
            {
                _logger.LogWarning("Skipping event image: EventId {EventId} does not exist.", seed.EventId);
                continue;
            }

            var existing = await _dbContext.EventImages
                .FirstOrDefaultAsync(i => i.EventId == seed.EventId && i.ImageUrl == seed.ImageUrl, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Event image already exists: EventId {EventId}", seed.EventId);
                continue;
            }

            var image = new EventImage(seed.EventId, seed.ImageUrl, seed.IsCover);

            await _dbContext.EventImages.AddAsync(image, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Event image created: EventId {EventId}, IsCover {IsCover}", image.EventId, image.IsCover);
        }
    }
}