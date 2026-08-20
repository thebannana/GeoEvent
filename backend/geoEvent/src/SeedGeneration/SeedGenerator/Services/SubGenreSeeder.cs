using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class SubGenreSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedSubGenreOptions> _subGenres;
    private readonly ILogger<SubGenreSeeder> _logger;

    public SubGenreSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<SubGenreSeeder> logger)
    {
        _dbContext = dbContext;
        _subGenres = options.Value.SeedSubGenres ?? new List<SeedSubGenreOptions>();
        _logger = logger;
    }

    public string Name => "subgenres";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_subGenres.Count == 0)
        {
            _logger.LogWarning("No subgenres configured in SeedSubGenres.");
            return;
        }

        foreach (var seed in _subGenres)
        {
            var genreExists = await _dbContext.Genres.AnyAsync(g => g.GenreId == seed.GenreId, cancellationToken);
            if (!genreExists)
            {
                _logger.LogWarning("Skipping subgenre: GenreId {GenreId} does not exist.", seed.GenreId);
                continue;
            }

            var normalizedName = seed.Name.Trim();
            var existing = await _dbContext.SubGenres
                .FirstOrDefaultAsync(sg => sg.GenreId == seed.GenreId && sg.Name == normalizedName, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("SubGenre already exists: {Name} (Genre {GenreId})", existing.Name, existing.GenreId);
                continue;
            }

            var subGenre = new SubGenre(seed.GenreId, normalizedName);

            await _dbContext.SubGenres.AddAsync(subGenre, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("SubGenre created: {Name} (Genre {GenreId})", subGenre.Name, subGenre.GenreId);
        }
    }
}