using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Domain.Entities;

namespace EventService.Infrastructure.Services;

public class EventServiceImpl : IEventService
{
    private readonly IEventRepository _eventRepository;

    public EventServiceImpl(IEventRepository eventRepository)
    {
        _eventRepository = eventRepository;
    }

    public async Task<ServiceResult<EventResponseDto>> GetByIdAsync(int eventId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        await _eventRepository.IncrementViewCountAsync(eventId);
        return ServiceResult<EventResponseDto>.Ok(MapToDto(ev));
    }

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter)
    {
        var result = await _eventRepository.GetAllAsync(filter);
        return ServiceResult<PagedResult<EventResponseDto>>.Ok(new PagedResult<EventResponseDto>
        {
            Items = result.Items.Select(MapToDto),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }

    public async Task<ServiceResult<EventResponseDto>> CreateAsync(
        CreateEventDto dto, int organizerId)
    {
        var entity = new Event
        {
            OrganizerId = organizerId,
            Title = dto.Title,
            Description = dto.Description,
            SegmentId = dto.SegmentId,
            GenreId = dto.GenreId,
            SubGenreId = dto.SubGenreId,
            VenueId = dto.VenueId,
            CityId = dto.CityId,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            StartDateTime = dto.StartDateTime,
            EndDateTime = dto.EndDateTime,
            Capacity = dto.Capacity,
            Price = dto.Price,
            IsOnline = dto.IsOnline,
            Tags = dto.Tags,
            ExternalUrl = dto.ExternalUrl,
            AccessibilityInfo = dto.AccessibilityInfo,
            PromoterName = dto.PromoterName,
            Locale = dto.Locale
        };

        var created = await _eventRepository.CreateAsync(entity);
        return ServiceResult<EventResponseDto>.Ok(MapToDto(created));
    }

    public async Task<ServiceResult<EventResponseDto>> UpdateAsync(
        int eventId, UpdateEventDto dto, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<EventResponseDto>.Forbidden("You do not own this event.");

        if (dto.Title is not null) ev.Title = dto.Title;
        if (dto.Description is not null) ev.Description = dto.Description;
        if (dto.SegmentId is not null) ev.SegmentId = dto.SegmentId;
        if (dto.GenreId is not null) ev.GenreId = dto.GenreId;
        if (dto.SubGenreId is not null) ev.SubGenreId = dto.SubGenreId;
        if (dto.VenueId is not null) ev.VenueId = dto.VenueId;
        if (dto.CityId is not null) ev.CityId = dto.CityId;
        if (dto.Latitude is not null) ev.Latitude = dto.Latitude.Value;
        if (dto.Longitude is not null) ev.Longitude = dto.Longitude.Value;
        if (dto.StartDateTime is not null) ev.StartDateTime = dto.StartDateTime.Value;
        if (dto.EndDateTime is not null) ev.EndDateTime = dto.EndDateTime.Value;
        if (dto.Capacity is not null) ev.Capacity = dto.Capacity.Value;
        if (dto.Price is not null) ev.Price = dto.Price.Value;
        if (dto.IsOnline is not null) ev.IsOnline = dto.IsOnline.Value;
        if (dto.Tags is not null) ev.Tags = dto.Tags;
        if (dto.ExternalUrl is not null) ev.ExternalUrl = dto.ExternalUrl;
        if (dto.AccessibilityInfo is not null) ev.AccessibilityInfo = dto.AccessibilityInfo;
        if (dto.PromoterName is not null) ev.PromoterName = dto.PromoterName;

        await _eventRepository.UpdateAsync(ev);
        return ServiceResult<EventResponseDto>.Ok(MapToDto(ev));
    }

    public async Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        await _eventRepository.DeleteAsync(eventId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        ev.Publish();
        await _eventRepository.UpdateAsync(ev);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        ev.Cancel();
        await _eventRepository.UpdateAsync(ev);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> LikeAsync(int eventId, int userId)
    {
        if (!await _eventRepository.ExistsAsync(eventId))
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (await _eventRepository.IsLikedByUserAsync(eventId, userId))
            return ServiceResult<bool>.Fail("Event already liked.");

        await _eventRepository.LikeAsync(eventId, userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId)
    {
        if (!await _eventRepository.ExistsAsync(eventId))
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        await _eventRepository.UnlikeAsync(eventId, userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> AddImageAsync(
        int eventId, string imageUrl, bool isCover)
    {
        if (!await _eventRepository.ExistsAsync(eventId))
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        await _eventRepository.AddImageAsync(new EventImage
        {
            EventId = eventId,
            ImageUrl = imageUrl,
            IsCover = isCover
        });
        return ServiceResult<bool>.Ok(true);
    }

    private static EventResponseDto MapToDto(Domain.Entities.Event ev) => new()
    {
        EventId = ev.EventId,
        OrganizerId = ev.OrganizerId,
        SegmentId = ev.SegmentId,
        GenreId = ev.GenreId,
        SubGenreId = ev.SubGenreId,
        VenueId = ev.VenueId,
        CityId = ev.CityId,
        Title = ev.Title,
        Description = ev.Description,
        Latitude = ev.Latitude,
        Longitude = ev.Longitude,
        StartDateTime = ev.StartDateTime,
        EndDateTime = ev.EndDateTime,
        Capacity = ev.Capacity,
        Price = ev.Price,
        Status = ev.Status.ToString(),
        IsOnline = ev.IsOnline,
        IsFeatured = ev.IsFeatured,
        ViewCount = ev.ViewCount,
        LikesCount = ev.LikesCount,
        Tags = ev.Tags,
        ExternalUrl = ev.ExternalUrl,
        AccessibilityInfo = ev.AccessibilityInfo,
        PromoterName = ev.PromoterName,
        Locale = ev.Locale,
        CreatedAt = ev.CreatedAt,
        UpdatedAt = ev.UpdatedAt,
        ImageUrls = ev.Images.Select(i => i.ImageUrl).ToList(),
        CoverImageUrl = ev.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
    };

    // ── Segments ──────────────────────────────────────────────────
    public async Task<ServiceResult<List<SegmentResponseDto>>> GetAllSegmentsAsync()
    {
        var segments = await _eventRepository.GetAllSegmentsAsync();
        return ServiceResult<List<SegmentResponseDto>>.Ok(segments.Select(MapSegment).ToList());
    }

    public async Task<ServiceResult<SegmentResponseDto>> GetSegmentByIdAsync(int segmentId)
    {
        var segment = await _eventRepository.GetSegmentByIdAsync(segmentId);
        if (segment is null)
            return ServiceResult<SegmentResponseDto>.NotFound("Segment not found.");
        return ServiceResult<SegmentResponseDto>.Ok(MapSegment(segment));
    }

    // ── Genres ────────────────────────────────────────────────────
    public async Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId)
    {
        var genres = await _eventRepository.GetGenresBySegmentAsync(segmentId);
        return ServiceResult<List<GenreResponseDto>>.Ok(genres.Select(MapGenre).ToList());
    }

    public async Task<ServiceResult<GenreResponseDto>> GetGenreByIdAsync(int genreId)
    {
        var genre = await _eventRepository.GetGenreByIdAsync(genreId);
        if (genre is null)
            return ServiceResult<GenreResponseDto>.NotFound("Genre not found.");
        return ServiceResult<GenreResponseDto>.Ok(MapGenre(genre));
    }

    // ── SubGenres ─────────────────────────────────────────────────
    public async Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId)
    {
        var subGenres = await _eventRepository.GetSubGenresByGenreAsync(genreId);
        return ServiceResult<List<SubGenreResponseDto>>.Ok(subGenres.Select(MapSubGenre).ToList());
    }

    // ── PriceZones ────────────────────────────────────────────────
    public async Task<ServiceResult<List<PriceZoneResponseDto>>> GetPriceZonesByVenueAsync(int venueId)
    {
        var zones = await _eventRepository.GetPriceZonesByVenueAsync(venueId);
        return ServiceResult<List<PriceZoneResponseDto>>.Ok(zones.Select(MapPriceZone).ToList());
    }

    public async Task<ServiceResult<PriceZoneResponseDto>> CreatePriceZoneAsync(CreatePriceZoneDto dto)
    {
        var priceZone = new PriceZone
        {
            VenueId = dto.VenueId,
            Name = dto.Name,
            Description = dto.Description,
            IsActive = true
        };
        var created = await _eventRepository.CreatePriceZoneAsync(priceZone);
        return ServiceResult<PriceZoneResponseDto>.Ok(MapPriceZone(created));
    }

    // ── Bookmarks ─────────────────────────────────────────────────
    public async Task<ServiceResult<List<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId)
    {
        var bookmarks = await _eventRepository.GetUserBookmarksAsync(userId);
        return ServiceResult<List<BookmarkResponseDto>>.Ok(bookmarks.Select(MapBookmark).ToList());
    }

    public async Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(
        CreateBookmarkDto dto, int userId)
    {
        var existing = await _eventRepository.GetBookmarkByUserAndEventAsync(userId, dto.EventId);
        if (existing is not null)
            return ServiceResult<BookmarkResponseDto>.Fail("Event already bookmarked.");

        var ev = await _eventRepository.GetByIdWithImagesAsync(dto.EventId);
        if (ev is null)
            return ServiceResult<BookmarkResponseDto>.NotFound("Event not found.");

        var imageUrl = ev.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
            ?? ev.Images.FirstOrDefault()?.ImageUrl
            ?? string.Empty;

        var bookmark = new Bookmark
        {
            EventId = dto.EventId,
            UserId = userId,
            Memo = dto.Memo,
            ImageUrl = imageUrl,
            SavedAt = DateTime.UtcNow
        };
        var created = await _eventRepository.CreateBookmarkAsync(bookmark);
        return ServiceResult<BookmarkResponseDto>.Ok(MapBookmark(created));
    }

    public async Task<ServiceResult<bool>> DeleteBookmarkAsync(int bookmarkId, int userId)
    {
        var bookmark = await _eventRepository.GetBookmarkByIdAsync(bookmarkId);
        if (bookmark is null)
            return ServiceResult<bool>.NotFound("Bookmark not found.");
        if (bookmark.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your bookmark.");

        await _eventRepository.DeleteBookmarkAsync(bookmark);
        return ServiceResult<bool>.Ok(true);
    }

    // ── Comments ──────────────────────────────────────────────────
    public async Task<ServiceResult<List<CommentResponseDto>>> GetEventCommentsAsync(int eventId)
    {
        var comments = await _eventRepository.GetEventCommentsAsync(eventId);
        return ServiceResult<List<CommentResponseDto>>.Ok(comments.Select(MapComment).ToList());
    }

    public async Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(
        CreateCommentDto dto, int userId)
    {
        var comment = new Comment
        {
            EventId = dto.EventId,
            UserId = userId,
            Content = dto.Content,
            ParentCommentId = dto.ParentCommentId,
            CreatedAt = DateTime.UtcNow,
            IsDeleted = false,
            LikesCount = 0
        };
        var created = await _eventRepository.CreateCommentAsync(comment);
        return ServiceResult<CommentResponseDto>.Ok(MapComment(created));
    }

    public async Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(
        int commentId, UpdateCommentDto dto, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");
        if (comment.UserId != userId)
            return ServiceResult<CommentResponseDto>.Forbidden("Not your comment.");
        if (comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.Fail("Comment has been deleted.");

        comment.Edit(dto.Content);
        await _eventRepository.UpdateCommentAsync(comment);
        return ServiceResult<CommentResponseDto>.Ok(MapComment(comment));
    }

    public async Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");
        if (comment.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your comment.");

        comment.Delete();
        await _eventRepository.UpdateCommentAsync(comment);
        return ServiceResult<bool>.Ok(true);
    }

    // ── Mappers ───────────────────────────────────────────────────
    private static SegmentResponseDto MapSegment(Segment s) => new()
    {
        SegmentId = s.SegmentId,
        Name = s.Name,
        IconUrl = s.IconUrl,
        Color = s.Color,
        IsActive = s.IsActive,
        Genres = s.Genres.Select(MapGenre).ToList()
    };

    private static GenreResponseDto MapGenre(Genre g) => new()
    {
        GenreId = g.GenreId,
        Name = g.Name,
        SegmentId = g.SegmentId,
        IsActive = g.IsActive,
        SubGenres = g.SubGenres.Select(MapSubGenre).ToList()
    };

    private static SubGenreResponseDto MapSubGenre(SubGenre s) => new()
    {
        SubGenreId = s.SubGenreId,
        Name = s.Name,
        GenreId = s.GenreId,
        IsActive = s.IsActive
    };

    private static PriceZoneResponseDto MapPriceZone(PriceZone p) => new()
    {
        PriceZoneId = p.PriceZoneId,
        VenueId = p.VenueId,
        Name = p.Name,
        Description = p.Description,
        IsActive = p.IsActive
    };

    private static BookmarkResponseDto MapBookmark(Bookmark b) => new()
    {
        BookmarkId = b.BookmarkId,
        ImageUrl = b.ImageUrl,
        SavedAt = b.SavedAt,
        Memo = b.Memo,
        EventId = b.EventId,
        UserId = b.UserId
    };

    private static CommentResponseDto MapComment(Comment c) => new()
    {
        CommentId = c.CommentId,
        Content = c.Content,
        LikesCount = c.LikesCount,
        UserId = c.UserId,
        EventId = c.EventId,
        CreatedAt = c.CreatedAt,
        UpdatedAt = c.UpdatedAt,
        IsDeleted = c.IsDeleted,
        ParentCommentId = c.ParentCommentId,
        Replies = c.Replies.Where(r => !r.IsDeleted).Select(MapComment).ToList()
    };

}
