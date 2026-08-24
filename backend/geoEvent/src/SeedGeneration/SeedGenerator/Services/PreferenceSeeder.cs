using EventService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Domain.Entities;
using UserService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public sealed class PreferenceSeeder : ISeeder
{
    private readonly UserDbContext _userDbContext;
    private readonly EventDbContext _eventDbContext;
    private readonly IReadOnlyList<SeedPreferenceOptions> _preferences;
    private readonly ILogger<PreferenceSeeder> _logger;

    public PreferenceSeeder(
        UserDbContext userDbContext,
        EventDbContext eventDbContext,
        IOptions<SeedSettings> options,
        ILogger<PreferenceSeeder> logger)
    {
        _userDbContext = userDbContext;
        _eventDbContext = eventDbContext;
        _preferences = options.Value.SeedPreferences
            ?? new List<SeedPreferenceOptions>();
        _logger = logger;
    }

    public string Name => "preferences";

    public async Task SeedAsync(
        CancellationToken cancellationToken = default)
    {
        if (_preferences.Count == 0)
        {
            _logger.LogWarning(
                "No preferences configured in SeedPreferences.");

            return;
        }

        var validPreferences = new List<SeedPreferenceOptions>();

        foreach (var seedPreference in _preferences)
        {
            if (!IsBasicConfigurationValid(seedPreference))
            {
                _logger.LogWarning(
                    "Skipping invalid preference configuration " +
                    "for UserId {UserId}.",
                    seedPreference.UserId);

                continue;
            }

            var userExists = await _userDbContext.Users.AnyAsync(
                user => user.PersonId == seedPreference.UserId,
                cancellationToken);

            if (!userExists)
            {
                _logger.LogWarning(
                    "Skipping preference: UserId {UserId} does not exist.",
                    seedPreference.UserId);

                continue;
            }

            var taxonomyPathIsValid =
                await IsTaxonomyPathValidAsync(
                    seedPreference,
                    cancellationToken);

            if (!taxonomyPathIsValid)
            {
                _logger.LogWarning(
                    "Skipping invalid event taxonomy path: " +
                    "UserId={UserId}, SegmentId={SegmentId}, " +
                    "GenreId={GenreId}, SubGenreId={SubGenreId}.",
                    seedPreference.UserId,
                    seedPreference.SegmentId,
                    seedPreference.GenreId,
                    seedPreference.SubGenreId);

                continue;
            }

            validPreferences.Add(seedPreference);
        }

        var generatedPreferences = ExpandAndAggregate(
            validPreferences);

        foreach (var generatedPreference in generatedPreferences)
        {
            var existing = await _userDbContext.UserPreferences
                .FirstOrDefaultAsync(
                    preference =>
                        preference.UserId ==
                            generatedPreference.UserId &&
                        preference.SegmentId ==
                            generatedPreference.SegmentId &&
                        preference.GenreId ==
                            generatedPreference.GenreId &&
                        preference.SubGenreId ==
                            generatedPreference.SubGenreId,
                    cancellationToken);

            if (existing is null)
            {
                await _userDbContext.UserPreferences.AddAsync(
                    generatedPreference,
                    cancellationToken);

                _logger.LogInformation(
                    "Created preference: UserId={UserId}, " +
                    "SegmentId={SegmentId}, GenreId={GenreId}, " +
                    "SubGenreId={SubGenreId}, Score={Score}.",
                    generatedPreference.UserId,
                    generatedPreference.SegmentId,
                    generatedPreference.GenreId,
                    generatedPreference.SubGenreId,
                    generatedPreference.Score);
            }
            else
            {
                existing.UpdateScore(generatedPreference.Score);

                _logger.LogInformation(
                    "Updated preference PrefId={PrefId}: UserId={UserId}, " +
                    "SegmentId={SegmentId}, GenreId={GenreId}, " +
                    "SubGenreId={SubGenreId}, Score={Score}.",
                    existing.PrefId,
                    existing.UserId,
                    existing.SegmentId,
                    existing.GenreId,
                    existing.SubGenreId,
                    existing.Score);
            }
        }

        await _userDbContext.SaveChangesAsync(cancellationToken);
    }

    private static bool IsBasicConfigurationValid(
        SeedPreferenceOptions preference)
    {
        if (preference.UserId <= 0)
            return false;

        if (!preference.SegmentId.HasValue)
            return false;

        if (preference.Score < 0)
            return false;

        if (preference.SubGenreId.HasValue &&
            !preference.GenreId.HasValue)
        {
            return false;
        }

        return true;
    }

    private async Task<bool> IsTaxonomyPathValidAsync(
        SeedPreferenceOptions preference,
        CancellationToken cancellationToken)
    {
        var segmentId = preference.SegmentId!.Value;

        var segmentExists = await _eventDbContext.Segments
            .AsNoTracking()
            .AnyAsync(
                segment => segment.SegmentId == segmentId,
                cancellationToken);

        if (!segmentExists)
            return false;

        if (!preference.GenreId.HasValue)
            return true;

        var genreId = preference.GenreId.Value;

        var genreExists = await _eventDbContext.Genres
            .AsNoTracking()
            .AnyAsync(
                genre =>
                    genre.GenreId == genreId &&
                    genre.SegmentId == segmentId,
                cancellationToken);

        if (!genreExists)
            return false;

        if (!preference.SubGenreId.HasValue)
            return true;

        var subGenreId = preference.SubGenreId.Value;

        return await _eventDbContext.SubGenres
            .AsNoTracking()
            .AnyAsync(
                subGenre =>
                    subGenre.SubGenreId == subGenreId &&
                    subGenre.GenreId == genreId,
                cancellationToken);
    }

    private static List<UserPreference> ExpandAndAggregate(
        IEnumerable<SeedPreferenceOptions> seedPreferences)
    {
        var result = new Dictionary<
            PreferenceKey,
            UserPreference>();

        foreach (var seed in seedPreferences)
        {
            var segmentId = seed.SegmentId!.Value;

            AddOrAccumulate(
                result,
                seed.UserId,
                segmentId,
                genreId: null,
                subGenreId: null,
                seed.Score);

            if (!seed.GenreId.HasValue)
                continue;

            var genreId = seed.GenreId.Value;

            AddOrAccumulate(
                result,
                seed.UserId,
                segmentId,
                genreId,
                subGenreId: null,
                seed.Score);

            if (!seed.SubGenreId.HasValue)
                continue;

            AddOrAccumulate(
                result,
                seed.UserId,
                segmentId,
                genreId,
                seed.SubGenreId.Value,
                seed.Score);
        }

        return result.Values.ToList();
    }

    private static void AddOrAccumulate(
        IDictionary<PreferenceKey, UserPreference> result,
        int userId,
        int? segmentId,
        int? genreId,
        int? subGenreId,
        double score)
    {
        var key = new PreferenceKey(
            userId,
            segmentId,
            genreId,
            subGenreId);

        if (result.TryGetValue(key, out var existing))
        {
            existing.Score += score;
            existing.LastUpdated = DateTime.UtcNow;
            return;
        }

        result[key] = new UserPreference
        {
            UserId = userId,
            SegmentId = segmentId,
            GenreId = genreId,
            SubGenreId = subGenreId,
            Score = score,
            LastUpdated = DateTime.UtcNow
        };
    }

    private readonly record struct PreferenceKey(
        int UserId,
        int? SegmentId,
        int? GenreId,
        int? SubGenreId);
}