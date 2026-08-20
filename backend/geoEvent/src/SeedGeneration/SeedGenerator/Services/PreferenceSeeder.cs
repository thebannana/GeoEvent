using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Domain.Entities;
using UserService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class PreferenceSeeder : ISeeder
{
    private readonly UserDbContext _dbContext;
    private readonly IReadOnlyList<SeedPreferenceOptions> _preferences;
    private readonly ILogger<PreferenceSeeder> _logger;

    public PreferenceSeeder(
        UserDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<PreferenceSeeder> logger)
    {
        _dbContext = dbContext;
        _preferences = options.Value.SeedPreferences ?? new List<SeedPreferenceOptions>();
        _logger = logger;
    }

    public string Name => "preferences";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_preferences.Count == 0)
        {
            _logger.LogWarning("No preferences configured in SeedPreferences.");
            return;
        }

        foreach (var seedPref in _preferences)
        {
            if (seedPref.UserId <= 0)
            {
                _logger.LogWarning("Skipping preference: UserId must be > 0.");
                continue;
            }

            var userExists = await _dbContext.Users.AnyAsync(u => u.PersonId == seedPref.UserId, cancellationToken);
            if (!userExists)
            {
                _logger.LogWarning("Skipping preference: UserId {UserId} does not exist.", seedPref.UserId);
                continue;
            }

            var existing = await _dbContext.UserPreferences
                .FirstOrDefaultAsync(
                    p => p.UserId == seedPref.UserId &&
                         p.SegmentId == seedPref.SegmentId &&
                         p.GenreId == seedPref.GenreId &&
                         p.SubGenreId == seedPref.SubGenreId,
                    cancellationToken);

            if (existing is not null)
            {
                existing.UpdateScore(seedPref.Score);
                _logger.LogInformation("Updated preference PrefId={PrefId} for UserId={UserId}", existing.PrefId, seedPref.UserId);
            }
            else
            {
                var preference = new UserPreference
                {
                    UserId = seedPref.UserId,
                    SegmentId = seedPref.SegmentId,
                    GenreId = seedPref.GenreId,
                    SubGenreId = seedPref.SubGenreId,
                    Score = seedPref.Score,
                    LastUpdated = DateTime.UtcNow
                };

                await _dbContext.UserPreferences.AddAsync(preference, cancellationToken);
                _logger.LogInformation("Created preference for UserId={UserId}, Segment={SegmentId}, Genre={GenreId}, SubGenre={SubGenreId}",
                    seedPref.UserId, seedPref.SegmentId, seedPref.GenreId, seedPref.SubGenreId);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}