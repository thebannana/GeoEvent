using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Domain.Entities;
using EventService.Domain.Enums;
using EventService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace EventService.Infrastructure.Repositories;

public class EventRepository : IEventRepository
{
    private const int DefaultPage = 1;
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 50;
    private const int DefaultNearbyRadiusKm = 50;
    private const int MaxNearbyRadiusKm = 500;
    private const int DefaultNearbyLimit = 20;
    private const int MaxNearbyLimit = 100;
    private const double MinCosLatitude = 0.000001d;
    private const double FeaturedScore = 4.0;
    private const double MaxPopularityScore = 12.0;
    private const double MaxDistanceScore = 8.0;
    private const double MaxTextScore = 90.0;

    private static readonly EventStatus[] ReservationStatuses =
    [
        EventStatus.Pending,
        EventStatus.Confirmed,
        EventStatus.Completed
    ];

    private readonly EventDbContext _context;

    public EventRepository(EventDbContext context)
    {
        _context = context;
    }

    public async Task<int> GetTotalEventsCountAsync() =>
    await _context.Events
        .AsNoTracking()
        .CountAsync();

    public async Task<int> GetEventsCountByStatusAsync(EventStatus status) =>
        await _context.Events
            .AsNoTracking()
            .CountAsync(e => e.Status == status);

    public async Task<int> GetTotalViewsCountAsync() =>
        await _context.Events
            .AsNoTracking()
            .SumAsync(e => (int?)e.ViewCount) ?? 0;

    public async Task<List<TopEventStatRawDto>> GetMostLikedEventsAsync(int take) =>
        await _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .OrderByDescending(e => e.LikesCount)
            .ThenByDescending(e => e.ViewCount)
            .ThenBy(e => e.EventId)
            .Take(take)
            .Select(e => new TopEventStatRawDto
            {
                EventId = e.EventId,
                Title = e.Title,
                ImageUrl = e.Images
                    .OrderByDescending(i => i.IsCover)
                    .ThenBy(i => i.ImageId)
                    .Select(i => i.ImageUrl)
                    .FirstOrDefault(),
                Status = e.Status,
                StartDateTime = e.StartDateTime,
                Count = e.LikesCount
            })
            .ToListAsync();

    public async Task<List<TopEventStatRawDto>> GetMostViewedEventsAsync(int take) =>
        await _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .OrderByDescending(e => e.ViewCount)
            .ThenByDescending(e => e.LikesCount)
            .ThenBy(e => e.EventId)
            .Take(take)
            .Select(e => new TopEventStatRawDto
            {
                EventId = e.EventId,
                Title = e.Title,
                ImageUrl = e.Images
                    .OrderByDescending(i => i.IsCover)
                    .ThenBy(i => i.ImageId)
                    .Select(i => i.ImageUrl)
                    .FirstOrDefault(),
                Status = e.Status,
                StartDateTime = e.StartDateTime,
                Count = e.ViewCount
            })
            .ToListAsync();

    public async Task<List<TopEventStatRawDto>> GetMostCommentedEventsAsync(int take) =>
        await _context.Comments
            .AsNoTracking()
            .Where(c => !c.IsDeleted)
            .GroupBy(c => new { c.EventId, c.Event!.Title, c.Event!.Status, c.Event!.StartDateTime })
            .Select(g => new TopEventStatRawDto
            {
                EventId = g.Key.EventId,
                Title = g.Key.Title,
                Status = g.Key.Status,
                StartDateTime = g.Key.StartDateTime,
                ImageUrl = _context.EventImages
                    .Where(i => i.EventId == g.Key.EventId)
                    .OrderByDescending(i => i.IsCover)
                    .ThenBy(i => i.ImageId)
                    .Select(i => i.ImageUrl)
                    .FirstOrDefault(),
                Count = g.Count()
            })
            .OrderByDescending(x => x.Count)
            .ThenBy(x => x.EventId)
            .Take(take)
            .ToListAsync();

    public async Task<List<TopEventStatRawDto>> GetMostBookmarkedEventsAsync(int take) =>
        await _context.Bookmarks
            .AsNoTracking()
            .GroupBy(b => new { b.EventId, b.Event!.Title, b.Event!.Status, b.Event!.StartDateTime })
            .Select(g => new TopEventStatRawDto
            {
                EventId = g.Key.EventId,
                Title = g.Key.Title,
                Status = g.Key.Status,
                StartDateTime = g.Key.StartDateTime,
                ImageUrl = _context.EventImages
                    .Where(i => i.EventId == g.Key.EventId)
                    .OrderByDescending(i => i.IsCover)
                    .ThenBy(i => i.ImageId)
                    .Select(i => i.ImageUrl)
                    .FirstOrDefault(),
                Count = g.Count()
            })
            .OrderByDescending(x => x.Count)
            .ThenBy(x => x.EventId)
            .Take(take)
            .ToListAsync();

    public async Task<int> GetBookmarksCountAsync() =>
    await _context.Bookmarks
        .AsNoTracking()
        .CountAsync();

    public async Task<int> GetCommentsCountAsync() =>
        await _context.Comments
            .AsNoTracking()
            .CountAsync(c => !c.IsDeleted);

    public async Task<int> GetLikedEventsCountAsync() =>
        await _context.EventLikes
            .AsNoTracking()
            .CountAsync();
    public async Task<PagedResult<Segment>> GetSegmentsPagedAsync(int page, int pageSize, string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.Segments
            .AsNoTracking()
            .Include(s => s.Genres)
                .ThenInclude(g => g.SubGenres)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.Trim();
            query = query.Where(s => s.Name.Contains(term));
        }

        query = query.OrderBy(s => s.Name).ThenBy(s => s.SegmentId);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Segment>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        };
    }

    public async Task<PagedResult<Genre>> GetGenresPagedAsync(int page, int pageSize, string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.Genres
            .AsNoTracking()
            .Include(g => g.Segment)
            .Include(g => g.SubGenres)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.Trim();
            query = query.Where(g =>
                g.Name.Contains(term) ||
                (g.Segment != null && g.Segment.Name.Contains(term)));
        }

        query = query
            .OrderBy(g => g.Name)
            .ThenBy(g => g.GenreId);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Genre>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        };
    }

    public async Task<PagedResult<SubGenre>> GetSubGenresPagedAsync(int page, int pageSize, string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.SubGenres
            .AsNoTracking()
            .Include(sg => sg.Genre)
                .ThenInclude(g => g!.Segment)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.Trim();
            query = query.Where(sg =>
                sg.Name.Contains(term) ||
                (sg.Genre != null && sg.Genre.Name.Contains(term)) ||
                (sg.Genre != null && sg.Genre.Segment != null && sg.Genre.Segment.Name.Contains(term)));
        }

        query = query
            .OrderBy(sg => sg.Name)
            .ThenBy(sg => sg.SubGenreId);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<SubGenre>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        };
    }

    public async Task<int> CountPublicByOrganizerAsync(int userId)
    {
        var nowUtc = DateTime.UtcNow;

        return await _context.Events
            .AsNoTracking()
            .Where(e => e.OrganizerId == userId)
            .Where(e => e.Status == EventStatus.Confirmed)
            .Where(e => e.EndDateTime > nowUtc)
            .CountAsync();
    }
    public async Task LikeAsync(int eventId, int userId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var alreadyLiked = await _context.EventLikes
                .AnyAsync(l => l.EventId == eventId && l.UserId == userId);

            if (!alreadyLiked)
            {
                await _context.EventLikes.AddAsync(new EventLike(eventId, userId));
                await _context.SaveChangesAsync();

                await _context.Events
                    .Where(e => e.EventId == eventId)
                    .ExecuteUpdateAsync(s =>
                        s.SetProperty(e => e.LikesCount, e => e.LikesCount + 1));
            }

            await transaction.CommitAsync();
        });
    }

    public async Task UnlikeAsync(int eventId, int userId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var deletedRows = await _context.EventLikes
                .Where(l => l.EventId == eventId && l.UserId == userId)
                .ExecuteDeleteAsync();

            if (deletedRows > 0)
            {
                await _context.Events
                    .Where(e => e.EventId == eventId && e.LikesCount > 0)
                    .ExecuteUpdateAsync(s =>
                        s.SetProperty(e => e.LikesCount, e => e.LikesCount - 1));
            }

            await transaction.CommitAsync();
        });
    }

    public async Task<Comment?> GetCommentTreeByIdAsync(int commentId)
    {
        return await _context.Comments
            .AsNoTracking()
            .Include(c => c.Replies)
                .ThenInclude(r => r.Replies)
            .FirstOrDefaultAsync(c => c.CommentId == commentId);
    }

    public async Task LikeCommentAsync(int commentId, int userId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var alreadyLiked = await _context.CommentLikes
                .AnyAsync(l => l.CommentId == commentId && l.UserId == userId);

            if (!alreadyLiked)
            {
                await _context.CommentLikes.AddAsync(new CommentLike(commentId, userId));
                await _context.SaveChangesAsync();

                await _context.Comments
                    .Where(c => c.CommentId == commentId)
                    .ExecuteUpdateAsync(s =>
                        s.SetProperty(c => c.LikesCount, c => c.LikesCount + 1));
            }

            await transaction.CommitAsync();
        });
    }

    public async Task UnlikeCommentAsync(int commentId, int userId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            var deletedRows = await _context.CommentLikes
                .Where(l => l.CommentId == commentId && l.UserId == userId)
                .ExecuteDeleteAsync();

            if (deletedRows > 0)
            {
                await _context.Comments
                    .Where(c => c.CommentId == commentId && c.LikesCount > 0)
                    .ExecuteUpdateAsync(s =>
                        s.SetProperty(c => c.LikesCount, c => c.LikesCount - 1));
            }

            await transaction.CommitAsync();
        });
    }

    public async Task<Event?> GetTrackedByIdAsync(int eventId) =>
        await _context.Events
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<Comment?> GetTrackedCommentByIdAsync(int commentId) =>
        await _context.Comments
            .Include(c => c.Replies)
            .FirstOrDefaultAsync(c => c.CommentId == commentId);

    public async Task<Segment?> GetTrackedSegmentByIdAsync(int segmentId) =>
        await _context.Segments
            .Include(s => s.Genres)
                .ThenInclude(g => g.SubGenres)
            .FirstOrDefaultAsync(s => s.SegmentId == segmentId);

    public async Task<Genre?> GetTrackedGenreByIdAsync(int genreId) =>
        await _context.Genres
            .Include(g => g.SubGenres)
            .FirstOrDefaultAsync(g => g.GenreId == genreId);

    public async Task<SubGenre?> GetTrackedSubGenreByIdAsync(int subGenreId) =>
        await _context.SubGenres
            .FirstOrDefaultAsync(s => s.SubGenreId == subGenreId);

    public async Task<Bookmark?> GetTrackedBookmarkByIdAsync(int bookmarkId) =>
        await _context.Bookmarks
            .Include(b => b.Event)
                .ThenInclude(e => e!.Images)
            .FirstOrDefaultAsync(b => b.BookmarkId == bookmarkId);

    public async Task<HashSet<int>> GetLikedEventIdsAsync(int userId, IEnumerable<int> eventIds)
    {
        var ids = eventIds
            .Distinct()
            .ToList();

        if (ids.Count == 0)
            return [];

        return await _context.EventLikes
            .AsNoTracking()
            .Where(l => l.UserId == userId && ids.Contains(l.EventId))
            .Select(l => l.EventId)
            .ToHashSetAsync();
    }

    public async Task<HashSet<int>> GetLikedCommentIdsAsync(int userId, IEnumerable<int> commentIds)
    {
        var ids = commentIds
            .Distinct()
            .ToList();

        if (ids.Count == 0)
            return [];

        return await _context.CommentLikes
            .AsNoTracking()
            .Where(l => l.UserId == userId && ids.Contains(l.CommentId))
            .Select(l => l.CommentId)
            .ToHashSetAsync();
    }

    public async Task<Comment?> GetCommentByIdAsync(int commentId)
    {
        return await _context.Comments
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CommentId == commentId);
    }

    public async Task<PagedResult<Comment>> GetEventCommentsAsync(int eventId, int page, int pageSize)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.Comments
            .AsNoTracking()
            .Where(c => c.EventId == eventId && c.ParentCommentId == null && !c.IsDeleted);

        var totalCount = await query.CountAsync();

        var items = await query
            .Include(c => c.Replies.Where(r => !r.IsDeleted))
            .OrderByDescending(c => c.CreatedAt)
            .ThenByDescending(c => c.CommentId)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Comment>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<PagedResult<Comment>> GetRepliesAsync(int parentCommentId, int page, int pageSize)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.Comments
            .AsNoTracking()
            .Where(c => c.ParentCommentId == parentCommentId && !c.IsDeleted);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderBy(c => c.CreatedAt)
            .ThenBy(c => c.CommentId)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Comment>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<Bookmark?> GetBookmarkByIdAsync(int bookmarkId)
    {
        return await _context.Bookmarks
            .AsNoTracking()
            .Include(b => b.Event)
                .ThenInclude(e => e!.Images)
            .FirstOrDefaultAsync(b => b.BookmarkId == bookmarkId);
    }

    public async Task<Bookmark?> GetBookmarkByUserAndEventAsync(int userId, int eventId)
    {
        return await _context.Bookmarks
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.UserId == userId && b.EventId == eventId);
    }

    public async Task<PagedResult<Bookmark>> GetUserBookmarksAsync(int userId, int page, int pageSize)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.Bookmarks
            .AsNoTracking()
            .Include(b => b.Event)
                .ThenInclude(e => e!.Images)
            .Where(b => b.UserId == userId);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(b => b.SavedAt)
            .ThenByDescending(b => b.BookmarkId)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Bookmark>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<Bookmark> CreateBookmarkAsync(Bookmark bookmark)
    {
        await _context.Bookmarks.AddAsync(bookmark);
        await _context.SaveChangesAsync();
        return bookmark;
    }

    public async Task UpdateBookmarkAsync(Bookmark bookmark)
    {
        await _context.SaveChangesAsync();
    }

    public async Task DeleteBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Event>> GetPublicCandidatesAsync(
    EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        IQueryable<Event> query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .Where(e =>
                e.Status == EventStatus.Confirmed &&
                e.EndDateTime > DateTime.UtcNow);

        if (filter.SegmentId.HasValue)
        {
            query = query.Where(e =>
                e.SegmentId == filter.SegmentId.Value);
        }

        if (filter.GenreId.HasValue)
        {
            query = query.Where(e =>
                e.GenreId == filter.GenreId.Value);
        }

        if (filter.SubGenreId.HasValue)
        {
            query = query.Where(e =>
                e.SubGenreId == filter.SubGenreId.Value);
        }

        if (filter.MinPrice.HasValue)
        {
            query = query.Where(e =>
                e.Price >= filter.MinPrice.Value);
        }

        if (filter.MaxPrice.HasValue)
        {
            query = query.Where(e =>
                e.Price <= filter.MaxPrice.Value);
        }

        if (filter.FromDate.HasValue)
        {
            query = query.Where(e =>
                e.StartDateTime >= filter.FromDate.Value);
        }

        if (filter.ToDate.HasValue)
        {
            query = query.Where(e =>
                e.StartDateTime <= filter.ToDate.Value);
        }

        if (filter.IsFeatured.HasValue)
        {
            query = query.Where(e =>
                e.IsFeatured == filter.IsFeatured.Value);
        }

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.Trim();

            query = query.Where(e =>
                e.Title.Contains(term) ||
                e.Description.Contains(term) ||
                (e.Tags != null && e.Tags.Contains(term)));
        }

        return await query
            .OrderBy(e => e.StartDateTime)
            .ThenBy(e => e.EventId)
            .ToListAsync();
    }

    public async Task<Comment> CreateCommentAsync(Comment comment)
    {
        await _context.Comments.AddAsync(comment);
        await _context.SaveChangesAsync();
        return comment;
    }

    public async Task UpdateCommentAsync(Comment comment)
    {
        await _context.SaveChangesAsync();
    }

    public async Task<bool> IsCommentLikedByUserAsync(int commentId, int userId)
    {
        return await _context.CommentLikes
            .AsNoTracking()
            .AnyAsync(l => l.CommentId == commentId && l.UserId == userId);
    }

    public async Task<Event?> GetByIdAsync(int eventId) =>
        await _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    public async Task<Event?> GetByIdWithDetailsAsync(int eventId) =>
        await _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .FirstOrDefaultAsync(e => e.EventId == eventId);

    private static double CalculateRecommendationScore(
    Event ev,
    decimal? userLatitude,
    decimal? userLongitude,
    double radiusKm,
    IReadOnlyList<UserPreferenceDto> preferences,
    string? searchTerm = null)
    {
        var preferenceScore =
            CalculatePreferenceScore(
                ev,
                preferences);

        var distanceScore =
            CalculateDistanceScore(
                ev,
                userLatitude,
                userLongitude,
                radiusKm);

        var popularityScore =
            CalculatePopularityScore(ev);

        var featuredScore = ev.IsFeatured
            ? FeaturedScore
            : 0.0;

        var textScore =
            string.IsNullOrWhiteSpace(searchTerm)
                ? 0.0
                : CalculateTextScore(
                    ev,
                    searchTerm);

        return preferenceScore +
               distanceScore +
               popularityScore +
               featuredScore +
               textScore;
    }

    private static double CalculatePreferenceScore(
    Event ev,
    IReadOnlyList<UserPreferenceDto> preferences)
    {
        if (preferences.Count == 0)
        {
            return 0.0;
        }

        var score = 0.0;

        foreach (var preference in preferences)
        {
            var matchesSegment =
                !preference.SegmentId.HasValue ||
                preference.SegmentId.Value ==
                    ev.SegmentId;

            var matchesGenre =
                !preference.GenreId.HasValue ||
                preference.GenreId.Value ==
                    ev.GenreId;

            var matchesSubGenre =
                !preference.SubGenreId.HasValue ||
                preference.SubGenreId.Value ==
                    ev.SubGenreId;

            if (!matchesSegment ||
                !matchesGenre ||
                !matchesSubGenre)
            {
                continue;
            }

            var specificity = 0;

            if (preference.SegmentId.HasValue)
            {
                specificity++;
            }

            if (preference.GenreId.HasValue)
            {
                specificity++;
            }

            if (preference.SubGenreId.HasValue)
            {
                specificity++;
            }

            var multiplier = specificity switch
            {
                3 => 3.0,
                2 => 2.0,
                1 => 1.0,
                _ => 0.25
            };

            score += preference.Score * multiplier;
        }

        return score;
    }

    private static double CalculateDistanceScore(
    Event ev,
    decimal? userLatitude,
    decimal? userLongitude,
    double radiusKm)
    {
        if (!userLatitude.HasValue ||
            !userLongitude.HasValue)
        {
            return 0.0;
        }

        var distanceKm = CalculateDistanceKm(
            (double)userLatitude.Value,
            (double)userLongitude.Value,
            (double)ev.Latitude,
            (double)ev.Longitude);

        if (distanceKm <= 2.0)
        {
            return MaxDistanceScore;
        }

        if (radiusKm <= 0.0 ||
            distanceKm >= radiusKm)
        {
            return 0.0;
        }

        var ratio = 1.0 -
            distanceKm / radiusKm;

        return Math.Clamp(
            ratio * MaxDistanceScore,
            0.0,
            MaxDistanceScore);
    }

    private static double CalculateDistanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2)
    {
        const double earthRadiusKm = 6371.0;

        var latitudeDelta =
            DegreesToRadians(latitude2 - latitude1);

        var longitudeDelta =
            DegreesToRadians(longitude2 - longitude1);

        var a =
            Math.Sin(latitudeDelta / 2.0) *
            Math.Sin(latitudeDelta / 2.0) +
            Math.Cos(DegreesToRadians(latitude1)) *
            Math.Cos(DegreesToRadians(latitude2)) *
            Math.Sin(longitudeDelta / 2.0) *
            Math.Sin(longitudeDelta / 2.0);

        var safeA = Math.Clamp(a, 0.0, 1.0);

        var c = 2.0 * Math.Atan2(
            Math.Sqrt(safeA),
            Math.Sqrt(1.0 - safeA));

        return earthRadiusKm * c;
    }

    private static double DegreesToRadians(
    double degrees)
    {
        return degrees * Math.PI / 180.0;
    }

    private static double CalculatePopularityScore(
    Event ev)
    {
        var likesScore =
            Math.Log(1.0 + ev.LikesCount) * 1.5;

        var viewsScore =
            Math.Log(1.0 + ev.ViewCount) * 0.5;

        return Math.Min(
            likesScore + viewsScore,
            MaxPopularityScore);
    }

    private static double CalculateTextScore(
    Event ev,
    string searchTerm)
    {
        var term = searchTerm.Trim();

        if (term.Length == 0)
        {
            return 0.0;
        }

        var score = 0.0;

        if (ev.Title.Contains(
            term,
            StringComparison.OrdinalIgnoreCase))
        {
            score += 90.0;
        }

        if (ev.Description.Contains(
            term,
            StringComparison.OrdinalIgnoreCase))
        {
            score += 30.0;
        }

        if (ev.Tags?.Contains(
            term,
            StringComparison.OrdinalIgnoreCase) == true)
        {
            score += 18.0;
        }

        return Math.Min(
            score,
            MaxTextScore);
    }

    public async Task<PagedResult<Event>> GetAllAsync(EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        var query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .AsQueryable();

        if (filter.Status.HasValue)
            query = query.Where(e => e.Status == filter.Status.Value);

        if (filter.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == filter.SegmentId.Value);

        if (filter.GenreId.HasValue)
            query = query.Where(e => e.GenreId == filter.GenreId.Value);

        if (filter.SubGenreId.HasValue)
            query = query.Where(e => e.SubGenreId == filter.SubGenreId.Value);

        if (filter.OrganizerId.HasValue)
            query = query.Where(e => e.OrganizerId == filter.OrganizerId.Value);

        if (filter.MinPrice.HasValue)
            query = query.Where(e => e.Price >= filter.MinPrice.Value);

        if (filter.MaxPrice.HasValue)
            query = query.Where(e => e.Price <= filter.MaxPrice.Value);

        if (filter.FromDate.HasValue)
            query = query.Where(e => e.StartDateTime >= filter.FromDate.Value);

        if (filter.ToDate.HasValue)
            query = query.Where(e => e.StartDateTime <= filter.ToDate.Value);

        if (filter.IsFeatured.HasValue)
            query = query.Where(e => e.IsFeatured == filter.IsFeatured.Value);

        if (filter.CanViewReservations.HasValue)
        {
            if (filter.CanViewReservations.Value)
                query = query.Where(e => ReservationStatuses.Contains(e.Status));
            else
                query = query.Where(e => !ReservationStatuses.Contains(e.Status));
        }

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.Trim();

            query = query.Where(e =>
                e.Title.Contains(term) ||
                e.Description.Contains(term) ||
                (e.Tags != null && e.Tags.Contains(term)));
        }

        var sortBy = filter.SortBy?.Trim().ToLowerInvariant()
             ?? "startdatetime";

        query = sortBy switch
        {
            "createdat" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.CreatedAt)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.CreatedAt)
                    .ThenBy(e => e.EventId),

            "title" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.Title)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.Title)
                    .ThenBy(e => e.EventId),

            "price" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.Price)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.Price)
                    .ThenBy(e => e.EventId),

            "likescount" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.LikesCount)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.LikesCount)
                    .ThenBy(e => e.EventId),

            "viewcount" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.ViewCount)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.ViewCount)
                    .ThenBy(e => e.EventId),

            "startdatetime" => filter.SortDescending
                ? query
                    .OrderByDescending(e => e.StartDateTime)
                    .ThenByDescending(e => e.EventId)
                : query
                    .OrderBy(e => e.StartDateTime)
                    .ThenBy(e => e.EventId),

            _ => query
                .OrderBy(e => e.StartDateTime)
                .ThenBy(e => e.EventId),
        };

        var page = NormalizePage(filter.Page);
        var pageSize = NormalizePageSize(filter.PageSize);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Event>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<RankedEvent>> GetNearbyRankedAsync(
    NearbyEventSearchDto dto,
    IReadOnlyList<UserPreferenceDto>? preferences = null)
    {
        var latitude = dto.Latitude!.Value;
        var longitude = dto.Longitude!.Value;

        var radiusKm = dto.RadiusKm <= 0
            ? DefaultNearbyRadiusKm
            : Math.Min(
                dto.RadiusKm,
                MaxNearbyRadiusKm);

        var limit = dto.Limit <= 0
            ? DefaultNearbyLimit
            : Math.Min(
                dto.Limit,
                MaxNearbyLimit);

        var latDelta =
            (decimal)(radiusKm / 111.0);

        var cosLatitude = Math.Cos(
            (double)latitude *
            Math.PI /
            180.0);

        if (Math.Abs(cosLatitude) <
            MinCosLatitude)
        {
            cosLatitude = MinCosLatitude;
        }

        var lonDelta = (decimal)(
            radiusKm /
            111.0 /
            Math.Abs(cosLatitude));

        var nowUtc = DateTime.UtcNow;

        IQueryable<Event> query = _context.Events
            .AsNoTracking()
            .Include(eventItem =>
                eventItem.Images)
            .Include(eventItem =>
                eventItem.Segment)
            .Include(eventItem =>
                eventItem.Genre)
            .Include(eventItem =>
                eventItem.SubGenre)
            .Where(eventItem =>
                eventItem.Status ==
                    EventStatus.Confirmed &&
                eventItem.EndDateTime > nowUtc &&
                eventItem.Latitude >=
                    latitude - latDelta &&
                eventItem.Latitude <=
                    latitude + latDelta &&
                eventItem.Longitude >=
                    longitude - lonDelta &&
                eventItem.Longitude <=
                    longitude + lonDelta);

        if (dto.SegmentId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.SegmentId ==
                dto.SegmentId.Value);
        }

        if (dto.GenreId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.GenreId ==
                dto.GenreId.Value);
        }

        if (dto.SubGenreId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.SubGenreId ==
                dto.SubGenreId.Value);
        }

        if (dto.MinPrice.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.Price >=
                dto.MinPrice.Value);
        }

        if (dto.MaxPrice.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.Price <=
                dto.MaxPrice.Value);
        }

        if (dto.TodayOnly)
        {
            var todayUtc = nowUtc.Date;
            var tomorrowUtc =
                todayUtc.AddDays(1);

            query = query.Where(eventItem =>
                eventItem.StartDateTime >= todayUtc &&
                eventItem.StartDateTime < tomorrowUtc);
        }

        var candidates =
            await query.ToListAsync();

        var activePreferences =
            preferences?
                .Where(preference =>
                    preference.SegmentId.HasValue ||
                    preference.GenreId.HasValue ||
                    preference.SubGenreId.HasValue)
                .ToList()
            ?? new List<UserPreferenceDto>();

        return candidates
            .Select(eventItem => new RankedEvent
            {
                Event = eventItem,
                Score = CalculateRecommendationScore(
                    eventItem,
                    latitude,
                    longitude,
                    radiusKm,
                    activePreferences)
            })
            .OrderByDescending(rankedItem =>
                rankedItem.Score)
            .ThenBy(rankedItem =>
                rankedItem.Event.StartDateTime)
            .ThenByDescending(rankedItem =>
                rankedItem.Event.LikesCount)
            .ThenBy(rankedItem =>
                rankedItem.Event.EventId)
            .Take(limit)
            .ToList();
    }

    public async Task<List<RankedEvent>> GetPublicRankedAsync(
    EventFilterDto filter,
    IReadOnlyList<UserPreferenceDto> preferences)
    {
        filter ??= new EventFilterDto();

        var nowUtc = DateTime.UtcNow;

        IQueryable<Event> query = _context.Events
            .AsNoTracking()
            .Include(eventItem => eventItem.Images)
            .Include(eventItem => eventItem.Segment)
            .Include(eventItem => eventItem.Genre)
            .Include(eventItem => eventItem.SubGenre)
            .Where(eventItem =>
                eventItem.Status ==
                    EventStatus.Confirmed &&
                eventItem.EndDateTime > nowUtc);

        if (filter.SegmentId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.SegmentId ==
                filter.SegmentId.Value);
        }

        if (filter.GenreId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.GenreId ==
                filter.GenreId.Value);
        }

        if (filter.SubGenreId.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.SubGenreId ==
                filter.SubGenreId.Value);
        }

        if (filter.MinPrice.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.Price >=
                filter.MinPrice.Value);
        }

        if (filter.MaxPrice.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.Price <=
                filter.MaxPrice.Value);
        }

        if (filter.FromDate.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.StartDateTime >=
                filter.FromDate.Value);
        }

        if (filter.ToDate.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.StartDateTime <=
                filter.ToDate.Value);
        }

        if (filter.IsFeatured.HasValue)
        {
            query = query.Where(eventItem =>
                eventItem.IsFeatured ==
                filter.IsFeatured.Value);
        }

        if (!string.IsNullOrWhiteSpace(
            filter.SearchTerm))
        {
            var term = filter.SearchTerm.Trim();

            query = query.Where(eventItem =>
                eventItem.Title.Contains(term) ||
                eventItem.Description.Contains(term) ||
                (eventItem.Tags != null &&
                 eventItem.Tags.Contains(term)));
        }

        var candidates =
            await query.ToListAsync();

        return candidates
            .Select(eventItem => new RankedEvent
            {
                Event = eventItem,
                Score = CalculateRecommendationScore(
                    eventItem,
                    filter.Latitude,
                    filter.Longitude,
                    25.0,
                    preferences,
                    filter.SearchTerm)
            })
            .OrderByDescending(rankedItem =>
                rankedItem.Score)
            .ThenBy(rankedItem =>
                rankedItem.Event.StartDateTime)
            .ThenByDescending(rankedItem =>
                rankedItem.Event.LikesCount)
            .ThenBy(rankedItem =>
                rankedItem.Event.EventId)
            .ToList();
    }
    public async Task<Event> CreateAsync(Event entity)
    {
        await _context.Events.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task UpdateAsync(Event entity)
    {
        await _context.SaveChangesAsync();
    }

    public async Task<bool> ExistsAsync(int eventId) =>
        await _context.Events
            .AsNoTracking()
            .AnyAsync(e => e.EventId == eventId);

    public async Task IncrementViewCountAsync(int eventId)
    {
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.ViewCount, e => e.ViewCount + 1));
    }

    public async Task<bool> IsLikedByUserAsync(int eventId, int userId) =>
        await _context.EventLikes
            .AsNoTracking()
            .AnyAsync(l => l.EventId == eventId && l.UserId == userId);

    public async Task<PagedResult<EventLike>> GetLikedEventsByUserAsync(int userId, int page, int pageSize)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var query = _context.EventLikes
            .AsNoTracking()
            .Include(x => x.Event)
                .ThenInclude(e => e!.Images)
            .Where(x => x.UserId == userId);

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(x => x.LikedAt)
            .ThenByDescending(x => x.EventId)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<EventLike>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task AddImageAsync(EventImage image, bool setAsCover)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            await _context.EventImages.AddAsync(image);
            await _context.SaveChangesAsync();

            if (setAsCover)
            {
                await _context.EventImages
                    .Where(i => i.EventId == image.EventId)
                    .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, false));

                await _context.EventImages
                    .Where(i => i.ImageId == image.ImageId)
                    .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, true));
            }

            await transaction.CommitAsync();
        });
    }

    public async Task DeleteImageAsync(int imageId)
    {
        await _context.EventImages
            .Where(i => i.ImageId == imageId)
            .ExecuteDeleteAsync();
    }

    public async Task<EventImage?> GetImageAsync(int imageId) =>
        await _context.EventImages
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.ImageId == imageId);

    public async Task<List<EventImage>> GetEventImagesAsync(int eventId) =>
        await _context.EventImages
            .AsNoTracking()
            .Where(i => i.EventId == eventId)
            .OrderByDescending(i => i.IsCover)
            .ThenBy(i => i.UploadedAt)
            .ThenBy(i => i.ImageId)
            .ToListAsync();

    public async Task SetCoverImageAsync(int eventId, int imageId)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();

            await _context.EventImages
                .Where(i => i.EventId == eventId)
                .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, false));

            await _context.EventImages
                .Where(i => i.EventId == eventId && i.ImageId == imageId)
                .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, true));

            await transaction.CommitAsync();
        });
    }

    public async Task<List<Segment>> GetAllSegmentsAsync() =>
        await _context.Segments
            .AsNoTracking()
            .Include(s => s.Genres)
                .ThenInclude(g => g.SubGenres)
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<Segment?> GetSegmentByIdAsync(int segmentId) =>
        await _context.Segments
            .AsNoTracking()
            .Include(s => s.Genres)
                .ThenInclude(g => g.SubGenres)
            .FirstOrDefaultAsync(s => s.SegmentId == segmentId);

    public async Task<List<Genre>> GetGenresBySegmentAsync(int segmentId) =>
        await _context.Genres
            .AsNoTracking()
            .Include(g => g.SubGenres)
            .Where(g => g.SegmentId == segmentId && g.IsActive)
            .OrderBy(g => g.Name)
            .ToListAsync();

    public async Task<Genre?> GetGenreByIdAsync(int genreId) =>
        await _context.Genres
            .AsNoTracking()
            .Include(g => g.SubGenres)
            .FirstOrDefaultAsync(g => g.GenreId == genreId);

    public async Task<List<SubGenre>> GetSubGenresByGenreAsync(int genreId) =>
        await _context.SubGenres
            .AsNoTracking()
            .Where(s => s.GenreId == genreId && s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();

    public async Task<SubGenre?> GetSubGenreByIdAsync(int subGenreId) =>
        await _context.SubGenres
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.SubGenreId == subGenreId);

    public async Task<Segment> CreateSegmentAsync(Segment segment)
    {
        await _context.Segments.AddAsync(segment);
        await _context.SaveChangesAsync();
        return segment;
    }

    public async Task UpdateSegmentAsync(Segment segment)
    {
        await _context.SaveChangesAsync();
    }

    public async Task<Genre> CreateGenreAsync(Genre genre)
    {
        await _context.Genres.AddAsync(genre);
        await _context.SaveChangesAsync();
        return genre;
    }

    public async Task UpdateGenreAsync(Genre genre)
    {
        await _context.SaveChangesAsync();
    }

    public async Task<SubGenre> CreateSubGenreAsync(SubGenre subGenre)
    {
        await _context.SubGenres.AddAsync(subGenre);
        await _context.SaveChangesAsync();
        return subGenre;
    }

    public async Task UpdateSubGenreAsync(SubGenre subGenre)
    {
        await _context.SaveChangesAsync();
    }

    private static int NormalizePage(int page) =>
        page < 1 ? DefaultPage : page;

    private static int NormalizePageSize(int pageSize) =>
        pageSize < 1
            ? DefaultPageSize
            : Math.Min(pageSize, MaxPageSize);
}