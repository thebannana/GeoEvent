using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class GenreSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedGenreOptions> _genres;
    private readonly ILogger<GenreSeeder> _logger;

    public GenreSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<GenreSeeder> logger)
    {
        _dbContext = dbContext;
        _genres = options.Value.SeedGenres ?? new List<SeedGenreOptions>();
        _logger = logger;
    }

    public string Name => "genres";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_genres.Count == 0)
        {
            _logger.LogWarning("No genres configured in SeedGenres.");
            return;
        }

        foreach (var seed in _genres)
        {
            var segmentExists = await _dbContext.Segments.AnyAsync(s => s.SegmentId == seed.SegmentId, cancellationToken);
            if (!segmentExists)
            {
                _logger.LogWarning("Skipping genre: SegmentId {SegmentId} does not exist.", seed.SegmentId);
                continue;
            }

            var normalizedName = seed.Name.Trim();
            var existing = await _dbContext.Genres
                .FirstOrDefaultAsync(g => g.SegmentId == seed.SegmentId && g.Name == normalizedName, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Genre already exists: {Name} (Segment {SegmentId})", existing.Name, existing.SegmentId);
                continue;
            }

            var genre = new Genre(seed.SegmentId, normalizedName);

            await _dbContext.Genres.AddAsync(genre, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Genre created: {Name} (Segment {SegmentId})", genre.Name, genre.SegmentId);
        }
    }
}