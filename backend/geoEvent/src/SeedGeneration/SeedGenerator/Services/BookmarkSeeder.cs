using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class BookmarkSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedBookmarkOptions> _bookmarks;
    private readonly ILogger<BookmarkSeeder> _logger;

    public BookmarkSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<BookmarkSeeder> logger)
    {
        _dbContext = dbContext;
        _bookmarks = options.Value.SeedBookmarks ?? new List<SeedBookmarkOptions>();
        _logger = logger;
    }

    public string Name => "bookmarks";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_bookmarks.Count == 0)
        {
            _logger.LogWarning("No bookmarks configured in SeedBookmarks.");
            return;
        }

        foreach (var seed in _bookmarks)
        {
            var eventExists = await _dbContext.Events.AnyAsync(e => e.EventId == seed.EventId, cancellationToken);
            if (!eventExists)
            {
                _logger.LogWarning("Skipping bookmark: EventId {EventId} does not exist.", seed.EventId);
                continue;
            }

            var existing = await _dbContext.Bookmarks
                .FirstOrDefaultAsync(b => b.EventId == seed.EventId && b.UserId == seed.UserId, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Bookmark already exists: EventId {EventId}, UserId {UserId}", seed.EventId, seed.UserId);
                continue;
            }

            var bookmark = new Bookmark(seed.EventId, seed.UserId, string.IsNullOrWhiteSpace(seed.Memo) ? null : seed.Memo.Trim());

            await _dbContext.Bookmarks.AddAsync(bookmark, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Bookmark created: EventId {EventId}, UserId {UserId}", bookmark.EventId, bookmark.UserId);
        }
    }
}