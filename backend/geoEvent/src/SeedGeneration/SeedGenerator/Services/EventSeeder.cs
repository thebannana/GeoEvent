using EventEntity = EventService.Domain.Entities.Event;
using EventService.Domain.Enums;
using EventService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Domain.Entities;
using UserService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class EventSeeder : ISeeder
{
    private readonly EventDbContext _eventDbContext;
    private readonly UserDbContext _userDbContext;
    private readonly IReadOnlyList<SeedEventOptions> _events;
    private readonly ILogger<EventSeeder> _logger;

    public EventSeeder(
        EventDbContext eventDbContext,
        UserDbContext userDbContext,
        IOptions<SeedSettings> options,
        ILogger<EventSeeder> logger)
    {
        _eventDbContext = eventDbContext;
        _userDbContext = userDbContext;
        _events = options.Value.SeedEvents ?? new List<SeedEventOptions>();
        _logger = logger;
    }

    public string Name => "events";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_events.Count == 0)
        {
            _logger.LogWarning("No events configured in SeedEvents.");
            return;
        }

        foreach (var seed in _events)
        {
            if (!Enum.TryParse<EventStatus>(seed.Status, true, out var targetStatus))
            {
                _logger.LogWarning("Skipping event: Invalid Status {Status}.", seed.Status);
                continue;
            }

            var segmentExists = await _eventDbContext.Segments.AnyAsync(s => s.SegmentId == seed.SegmentId, cancellationToken);
            var genreExists = await _eventDbContext.Genres.AnyAsync(g => g.GenreId == seed.GenreId, cancellationToken);
            var subGenreExists = seed.SubGenreId.HasValue && await _eventDbContext.SubGenres.AnyAsync(sg => sg.SubGenreId == seed.SubGenreId.Value, cancellationToken);

            if (!segmentExists || !genreExists || (seed.SubGenreId.HasValue && !subGenreExists))
            {
                _logger.LogWarning("Skipping event: Invalid Segment/Genre/SubGenre references.");
                continue;
            }

            User? organizer = null;

            if (!string.IsNullOrWhiteSpace(seed.OrganizerUsername))
            {
                var normalizedUsername = seed.OrganizerUsername.Trim().ToLowerInvariant();
                organizer = await _userDbContext.Users
                    .Include(u => u.Person)
                    .FirstOrDefaultAsync(u => u.Username == normalizedUsername, cancellationToken);

                if (organizer is null)
                {
                    _logger.LogWarning(
                        "Skipping event '{Title}': organizer '{Username}' not found.",
                        seed.Title,
                        seed.OrganizerUsername);
                    continue;
                }
            }
            else if (seed.OrganizerId.HasValue && seed.OrganizerId.Value > 0)
            {
                organizer = await _userDbContext.Users
                    .Include(u => u.Person)
                    .FirstOrDefaultAsync(u => u.PersonId == seed.OrganizerId.Value, cancellationToken);

                if (organizer is null)
                {
                    _logger.LogWarning(
                        "Skipping event '{Title}': organizer with ID {OrganizerId} not found.",
                        seed.Title,
                        seed.OrganizerId.Value);
                    continue;
                }
            }
            else
            {
                _logger.LogWarning(
                    "Skipping event '{Title}': either OrganizerUsername or a valid OrganizerId must be provided.",
                    seed.Title);
                continue;
            }

            var existing = await _eventDbContext.Events
                .FirstOrDefaultAsync(e =>
                    e.OrganizerId == organizer.PersonId &&
                    e.Title == seed.Title.Trim() &&
                    e.StartDateTime == seed.StartDateTime,
                    cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Event already exists: {Title} by Organizer {OrganizerId}", existing.Title, existing.OrganizerId);
                continue;
            }

            var ev = new EventEntity(
                organizer.PersonId,
                seed.SegmentId,
                seed.GenreId,
                seed.SubGenreId,
                seed.Title.Trim(),
                seed.Description.Trim(),
                seed.Latitude,
                seed.Longitude,
                seed.StartDateTime,
                seed.EndDateTime,
                seed.Capacity,
                seed.Price,
                isFeatured: seed.IsFeatured,
                tags: string.IsNullOrWhiteSpace(seed.Tags) ? null : seed.Tags.Trim(),
                accessibilityInfo: string.IsNullOrWhiteSpace(seed.AccessibilityInfo) ? null : seed.AccessibilityInfo.Trim(),
                promoterName: string.IsNullOrWhiteSpace(seed.PromoterName) ? null : seed.PromoterName.Trim(),
                locale: string.IsNullOrWhiteSpace(seed.Locale) ? "bs-BA" : seed.Locale.Trim());

            switch (targetStatus)
            {
                case EventStatus.Pending:
                    break;

                case EventStatus.Confirmed:
                    ev.Publish();
                    break;

                case EventStatus.Cancelled:
                    ev.Publish();
                    ev.Cancel();
                    break;

                case EventStatus.Completed:
                    ev.Publish();
                    ev.Complete();
                    break;

                default:
                    throw new InvalidOperationException(
                        $"Unsupported event status '{targetStatus}' for event '{seed.Title}'.");
            }

            await _eventDbContext.Events.AddAsync(ev, cancellationToken);
            await _eventDbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Event created: {Title} (Status {Status})", ev.Title, ev.Status);
        }
    }
}