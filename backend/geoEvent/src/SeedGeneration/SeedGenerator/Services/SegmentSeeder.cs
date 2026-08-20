using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class SegmentSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedSegmentOptions> _segments;
    private readonly ILogger<SegmentSeeder> _logger;

    public SegmentSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<SegmentSeeder> logger)
    {
        _dbContext = dbContext;
        _segments = options.Value.SeedSegments ?? new List<SeedSegmentOptions>();
        _logger = logger;
    }

    public string Name => "segments";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_segments.Count == 0)
        {
            _logger.LogWarning("No segments configured in SeedSegments.");
            return;
        }

        foreach (var seed in _segments)
        {
            var normalizedName = seed.Name.Trim();
            var existing = await _dbContext.Segments
                .FirstOrDefaultAsync(s => s.Name == normalizedName, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Segment already exists: {Name}", existing.Name);
                continue;
            }

            var segment = new Segment(normalizedName, seed.Color);

            await _dbContext.Segments.AddAsync(segment, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Segment created: {Name}", segment.Name);
        }
    }
}