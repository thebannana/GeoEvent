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
    private readonly EventDbContext _context;

    public EventRepository(EventDbContext context)
    {
        _context = context;
    }

    public async Task<Comment?> GetCommentByIdAsync(int commentId)
    {
        return await _context.Comments
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.CommentId == commentId && !c.IsDeleted);
    }

    public async Task<PagedResult<Comment>> GetEventCommentsAsync(int eventId, int page, int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        var query = _context.Comments
            .AsNoTracking()
            .Where(c => c.EventId == eventId && c.ParentCommentId == null && !c.IsDeleted);

        var totalCount = await query.CountAsync();

        var items = await query
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
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

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
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

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
        _context.Bookmarks.Add(bookmark);
        await _context.SaveChangesAsync();
        return bookmark;
    }

    public async Task UpdateBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Update(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteBookmarkAsync(Bookmark bookmark)
    {
        _context.Bookmarks.Remove(bookmark);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Event>> GetPublicCandidatesAsync(EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        var query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .Where(e => e.Status == EventStatus.Confirmed)
            .AsQueryable();

        if (filter.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == filter.SegmentId.Value);

        if (filter.GenreId.HasValue)
            query = query.Where(e => e.GenreId == filter.GenreId.Value);

        if (filter.SubGenreId.HasValue)
            query = query.Where(e => e.SubGenreId == filter.SubGenreId.Value);

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
        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();
        return comment;
    }

    public async Task UpdateCommentAsync(Comment comment)
    {
        _context.Comments.Update(comment);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> IsCommentLikedByUserAsync(int commentId, int userId)
    {
        return await _context.CommentLikes
            .AnyAsync(l => l.CommentId == commentId && l.UserId == userId);
    }

    public async Task LikeCommentAsync(int commentId, int userId)
    {
        _context.CommentLikes.Add(new CommentLike(commentId, userId));
        await _context.SaveChangesAsync();

        await _context.Comments
            .Where(c => c.CommentId == commentId)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.LikesCount, c => c.LikesCount + 1));
    }

    public async Task UnlikeCommentAsync(int commentId, int userId)
    {
        var deletedRows = await _context.CommentLikes
            .Where(l => l.CommentId == commentId && l.UserId == userId)
            .ExecuteDeleteAsync();

        if (deletedRows > 0)
        {
            await _context.Comments
                .Where(c => c.CommentId == commentId && c.LikesCount > 0)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.LikesCount, c => c.LikesCount - 1));
        }
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
            var reservationStatuses = new[]
            {
            EventStatus.Pending,
            EventStatus.Confirmed,
            EventStatus.Completed
        };

            if (filter.CanViewReservations.Value)
            {
                query = query.Where(e => reservationStatuses.Contains(e.Status));
            }
            else
            {
                query = query.Where(e => !reservationStatuses.Contains(e.Status));
            }
        }

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.Trim();

            query = query.Where(e =>
                e.Title.Contains(term) ||
                e.Description.Contains(term) ||
                (e.Tags != null && e.Tags.Contains(term)));
        }

        var sortBy = filter.SortBy?.Trim().ToLowerInvariant() ?? "startdatetime";

        query = sortBy switch
        {
            "price" => filter.SortDescending
                ? query.OrderByDescending(e => e.Price).ThenByDescending(e => e.EventId)
                : query.OrderBy(e => e.Price).ThenBy(e => e.EventId),

            "likescount" => filter.SortDescending
                ? query.OrderByDescending(e => e.LikesCount).ThenByDescending(e => e.EventId)
                : query.OrderBy(e => e.LikesCount).ThenBy(e => e.EventId),

            "viewcount" => filter.SortDescending
                ? query.OrderByDescending(e => e.ViewCount).ThenByDescending(e => e.EventId)
                : query.OrderBy(e => e.ViewCount).ThenBy(e => e.EventId),

            _ => filter.SortDescending
                ? query.OrderByDescending(e => e.StartDateTime).ThenByDescending(e => e.EventId)
                : query.OrderBy(e => e.StartDateTime).ThenBy(e => e.EventId),
        };

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 50);

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

    public async Task<List<Event>> GetNearbyAsync(NearbyEventSearchDto dto)
    {
        var latitude = dto.Latitude!.Value;
        var longitude = dto.Longitude!.Value;

        var radiusKm = dto.RadiusKm <= 0 ? 50 : Math.Min(dto.RadiusKm, 500);
        var limit = dto.Limit <= 0 ? 20 : Math.Min(dto.Limit, 100);

        var latDelta = (decimal)(radiusKm / 111.0);

        var cosLatitude = Math.Cos((double)latitude * Math.PI / 180.0);
        if (Math.Abs(cosLatitude) < 0.000001)
            cosLatitude = 0.000001;

        var lonDelta = (decimal)(radiusKm / 111.0 / Math.Abs(cosLatitude));
        var nowUtc = DateTime.UtcNow;

        IQueryable<Event> query = _context.Events
            .AsNoTracking()
            .Include(e => e.Images)
            .Include(e => e.Segment)
            .Include(e => e.Genre)
            .Include(e => e.SubGenre)
            .Where(e =>
                e.Status == EventStatus.Confirmed &&
                e.EndDateTime > nowUtc &&
                e.Latitude >= latitude - latDelta &&
                e.Latitude <= latitude + latDelta &&
                e.Longitude >= longitude - lonDelta &&
                e.Longitude <= longitude + lonDelta);

        if (dto.SegmentId.HasValue)
            query = query.Where(e => e.SegmentId == dto.SegmentId.Value);

        if (dto.GenreId.HasValue)
            query = query.Where(e => e.GenreId == dto.GenreId.Value);

        if (dto.SubGenreId.HasValue)
            query = query.Where(e => e.SubGenreId == dto.SubGenreId.Value);

        if (dto.MinPrice.HasValue)
            query = query.Where(e => e.Price >= dto.MinPrice.Value);

        if (dto.MaxPrice.HasValue)
            query = query.Where(e => e.Price <= dto.MaxPrice.Value);

        if (dto.TodayOnly)
        {
            var today = nowUtc.Date;
            var tomorrow = today.AddDays(1);

            query = query.Where(e =>
                e.StartDateTime >= today &&
                e.StartDateTime < tomorrow);
        }

        return await query
            .OrderBy(e => e.StartDateTime)
            .ThenBy(e => e.EventId)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<Event> CreateAsync(Event entity)
    {
        await _context.Events.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task UpdateAsync(Event entity)
    {
        _context.Events.Update(entity);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(int eventId)
    {
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteDeleteAsync();
    }

    public async Task<bool> ExistsAsync(int eventId) =>
        await _context.Events.AnyAsync(e => e.EventId == eventId);

    public async Task IncrementViewCountAsync(int eventId)
    {
        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.ViewCount, e => e.ViewCount + 1));
    }

    public async Task<bool> IsLikedByUserAsync(int eventId, int userId) =>
        await _context.EventLikes
            .AnyAsync(l => l.EventId == eventId && l.UserId == userId);

    public async Task LikeAsync(int eventId, int userId)
    {
        await _context.EventLikes.AddAsync(new EventLike(eventId, userId));
        await _context.SaveChangesAsync();

        await _context.Events
            .Where(e => e.EventId == eventId)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(e => e.LikesCount, e => e.LikesCount + 1));
    }

    public async Task UnlikeAsync(int eventId, int userId)
    {
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
    }

    public async Task<PagedResult<EventLike>> GetLikedEventsByUserAsync(int userId, int page, int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

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

    public async Task AddImageAsync(EventImage image)
    {
        await _context.EventImages.AddAsync(image);
        await _context.SaveChangesAsync();
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
        await _context.EventImages
            .Where(i => i.EventId == eventId)
            .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, false));

        await _context.EventImages
            .Where(i => i.EventId == eventId && i.ImageId == imageId)
            .ExecuteUpdateAsync(s => s.SetProperty(i => i.IsCover, true));
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
        _context.Segments.Add(segment);
        await _context.SaveChangesAsync();
        return segment;
    }

    public async Task UpdateSegmentAsync(Segment segment)
    {
        _context.Segments.Update(segment);
        await _context.SaveChangesAsync();
    }

    public async Task<Genre> CreateGenreAsync(Genre genre)
    {
        _context.Genres.Add(genre);
        await _context.SaveChangesAsync();
        return genre;
    }

    public async Task UpdateGenreAsync(Genre genre)
    {
        _context.Genres.Update(genre);
        await _context.SaveChangesAsync();
    }

    public async Task<SubGenre> CreateSubGenreAsync(SubGenre subGenre)
    {
        _context.SubGenres.Add(subGenre);
        await _context.SaveChangesAsync();
        return subGenre;
    }

    public async Task UpdateSubGenreAsync(SubGenre subGenre)
    {
        _context.SubGenres.Update(subGenre);
        await _context.SaveChangesAsync();
    }
}