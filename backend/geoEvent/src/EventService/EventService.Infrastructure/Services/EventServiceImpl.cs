using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Domain.Entities;
using EventService.Domain.Enums;
using EventService.Domain.Exceptions;
using MassTransit;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Events;
using DomainEvent = EventService.Domain.Entities.Event;

namespace EventService.Infrastructure.Services;

public class EventServiceImpl : IEventService
{
    private readonly IEventRepository _eventRepository;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IUserProfileService _userProfileService;
    private readonly ILogger<EventServiceImpl> _logger;

    public EventServiceImpl(
        IEventRepository eventRepository,
        IPublishEndpoint publishEndpoint,
        IUserProfileService userProfileService,
        ILogger<EventServiceImpl> logger)
    {
        _eventRepository = eventRepository;
        _publishEndpoint = publishEndpoint;
        _userProfileService = userProfileService;
        _logger = logger;
    }

    public async Task<ServiceResult<PagedResult<CommentResponseDto>>> GetEventCommentsAsync(
    int eventId,
    int page,
    int pageSize,
    int? requesterId = null)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        var pagedComments = await _eventRepository.GetEventCommentsAsync(eventId, page, pageSize);
        var mapped = pagedComments.Items.Select(c => MapComment(c, includeReplies: false)).ToList();

        await EnrichCommentsAsync(mapped, requesterId);

        return ServiceResult<PagedResult<CommentResponseDto>>.Ok(
            new PagedResult<CommentResponseDto>
            {
                Items = mapped,
                TotalCount = pagedComments.TotalCount,
                Page = pagedComments.Page,
                PageSize = pagedComments.PageSize
            });
    }

    public async Task<ServiceResult<PagedResult<CommentResponseDto>>> GetRepliesAsync(
        int commentId,
        int page,
        int pageSize,
        int? requesterId = null)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        var pagedReplies = await _eventRepository.GetRepliesAsync(commentId, page, pageSize);
        var mapped = pagedReplies.Items.Select(c => MapComment(c, includeReplies: false)).ToList();

        await EnrichCommentsAsync(mapped, requesterId);

        return ServiceResult<PagedResult<CommentResponseDto>>.Ok(
            new PagedResult<CommentResponseDto>
            {
                Items = mapped,
                TotalCount = pagedReplies.TotalCount,
                Page = pagedReplies.Page,
                PageSize = pagedReplies.PageSize
            });
    }

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter)
    {
        filter ??= new EventFilterDto();

        var result = await _eventRepository.GetAllAsync(filter);

        return ServiceResult<PagedResult<EventResponseDto>>.Ok(
            new PagedResult<EventResponseDto>
            {
                Items = result.Items.Select(ev => MapToDto(ev, false)).ToList(),
                TotalCount = result.TotalCount,
                Page = result.Page,
                PageSize = result.PageSize
            });
    }

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetPublicAsync(
        EventFilterDto filter,
        int? requesterId = null)
    {
        filter ??= new EventFilterDto();
        filter.Status = EventStatus.Confirmed;
        filter.OrganizerId = null;

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 50);
        filter.Page = page;
        filter.PageSize = pageSize;

        if (!requesterId.HasValue)
        {
            var result = await _eventRepository.GetAllAsync(filter);

            return ServiceResult<PagedResult<EventResponseDto>>.Ok(
                new PagedResult<EventResponseDto>
                {
                    Items = result.Items.Select(ev => MapToDto(ev, false)).ToList(),
                    TotalCount = result.TotalCount,
                    Page = result.Page,
                    PageSize = result.PageSize
                });
        }

        var preferences = await _userProfileService.GetUserPreferencesAsync(requesterId.Value);

        if (preferences.Count == 0)
        {
            var result = await _eventRepository.GetAllAsync(filter);
            var mapped = new List<EventResponseDto>();

            foreach (var ev in result.Items)
            {
                var isLiked = await _eventRepository.IsLikedByUserAsync(ev.EventId, requesterId.Value);
                mapped.Add(MapToDto(ev, isLiked));
            }

            return ServiceResult<PagedResult<EventResponseDto>>.Ok(
                new PagedResult<EventResponseDto>
                {
                    Items = mapped,
                    TotalCount = result.TotalCount,
                    Page = result.Page,
                    PageSize = result.PageSize
                });
        }

        var personalizedCandidates = await _eventRepository.GetPublicCandidatesAsync(filter);

        var ranked = personalizedCandidates
            .Select(ev => new
            {
                Event = ev,
                Score = CalculatePreferenceScore(ev, preferences)
            })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Event.StartDateTime)
            .ThenByDescending(x => x.Event.LikesCount)
            .ThenBy(x => x.Event.EventId)
            .ToList();

        var totalCount = ranked.Count;

        var paged = ranked
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var personalizedItems = new List<EventResponseDto>(paged.Count);

        foreach (var item in paged)
        {
            var isLiked = await _eventRepository.IsLikedByUserAsync(item.Event.EventId, requesterId.Value);
            personalizedItems.Add(MapToDto(item.Event, isLiked));
        }

        return ServiceResult<PagedResult<EventResponseDto>>.Ok(
            new PagedResult<EventResponseDto>
            {
                Items = personalizedItems,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            });
    }

    public async Task<ServiceResult<EventResponseDto>> GetPublicByIdAsync(int eventId, int? requesterId = null)
    {
        var ev = await _eventRepository.GetByIdWithDetailsAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (ev.Status != EventStatus.Confirmed && ev.OrganizerId != requesterId)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (!requesterId.HasValue || ev.OrganizerId != requesterId.Value)
        {
            await _eventRepository.IncrementViewCountAsync(eventId);
            ev.IncrementView();
        }

        var isLiked = false;
        if (requesterId.HasValue)
            isLiked = await _eventRepository.IsLikedByUserAsync(eventId, requesterId.Value);

        return ServiceResult<EventResponseDto>.Ok(MapToDto(ev, isLiked));
    }

    public async Task<ServiceResult<PagedResult<LikedEventResponseDto>>> GetLikedEventsAsync(int userId, int page, int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        var pagedLikes = await _eventRepository.GetLikedEventsByUserAsync(userId, page, pageSize);

        var items = pagedLikes.Items
            .Select(x => new LikedEventResponseDto
            {
                EventId = x.EventId,
                Title = x.Event?.Title ?? $"Event #{x.EventId}",
                ImageUrl = x.Event?.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
                           ?? x.Event?.Images.FirstOrDefault()?.ImageUrl,
                LikedAt = x.LikedAt,
                IsLiked = true
            })
            .ToList();

        return ServiceResult<PagedResult<LikedEventResponseDto>>.Ok(
            new PagedResult<LikedEventResponseDto>
            {
                Items = items,
                TotalCount = pagedLikes.TotalCount,
                Page = pagedLikes.Page,
                PageSize = pagedLikes.PageSize
            });
    }

    public async Task<ServiceResult<List<EventResponseDto>>> GetNearbyPublicAsync(NearbyEventSearchDto dto)
    {
        if (dto.Latitude is null || dto.Longitude is null)
            return ServiceResult<List<EventResponseDto>>.Fail("Latitude and Longitude are required.");

        if (dto.RadiusKm <= 0 || dto.RadiusKm > 500)
            return ServiceResult<List<EventResponseDto>>.Fail("Radius must be between 1 and 500 km.");

        if (dto.Limit <= 0 || dto.Limit > 100)
            return ServiceResult<List<EventResponseDto>>.Fail("Limit must be between 1 and 100.");

        var events = await _eventRepository.GetNearbyAsync(dto);

        var publicEvents = events
            .Where(e => e.Status == EventStatus.Confirmed && !e.IsPast())
            .Select(e => MapToDto(e, false))
            .ToList();

        return ServiceResult<List<EventResponseDto>>.Ok(publicEvents);
    }

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetMyPendingAsync(EventFilterDto filter, int requesterId)
    {
        filter ??= new EventFilterDto();
        filter.OrganizerId = requesterId;
        filter.Status = EventStatus.Pending;

        var result = await _eventRepository.GetAllAsync(filter);

        return ServiceResult<PagedResult<EventResponseDto>>.Ok(new PagedResult<EventResponseDto>
        {
            Items = result.Items.Select(ev => MapToDto(ev, false)).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }

    public async Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId)
    {
        try
        {
            var entity = new DomainEvent(
            organizerId: organizerId,
            segmentId: dto.SegmentId,
            genreId: dto.GenreId,
            subGenreId: dto.SubGenreId,
            title: dto.Title,
            description: dto.Description,
            latitude: dto.Latitude,
            longitude: dto.Longitude,
            startDateTime: dto.StartDateTime,
            endDateTime: dto.EndDateTime,
            capacity: dto.Capacity,
            price: dto.Price,
            isOnline: dto.IsOnline,
            isFeatured: false,
            tags: dto.Tags,
            externalUrl: dto.ExternalUrl,
            externalSource: null,
            externalId: null,
            accessibilityInfo: dto.AccessibilityInfo,
            promoterName: dto.PromoterName,
            locale: dto.Locale
        );

            var created = await _eventRepository.CreateAsync(entity);

            await _publishEndpoint.Publish(new EventCreatedMessage(
                created.EventId,
                created.Title,
                created.OrganizerId,
                created.SegmentId,
                created.GenreId,
                created.SubGenreId,
                created.Latitude,
                created.Longitude,
                created.Price,
                created.Price == 0,
                created.Capacity,
                created.IsOnline,
                created.StartDateTime,
                created.EndDateTime,
                DateTime.UtcNow
            ));

            return ServiceResult<EventResponseDto>.Created(MapToDto(created));
        }
        catch (InvalidEventDataException ex)
        {
            return ServiceResult<EventResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<EventResponseDto>.Forbidden("You do not own this event.");

        try
        {
            ev.UpdateDetails(
                segmentId: dto.SegmentId ?? ev.SegmentId,
                genreId: dto.GenreId ?? ev.GenreId,
                subGenreId: dto.SubGenreId ?? ev.SubGenreId,
                title: dto.Title ?? ev.Title,
                description: dto.Description ?? ev.Description,
                latitude: dto.Latitude ?? ev.Latitude,
                longitude: dto.Longitude ?? ev.Longitude,
                startDateTime: dto.StartDateTime ?? ev.StartDateTime,
                endDateTime: dto.EndDateTime ?? ev.EndDateTime,
                capacity: dto.Capacity ?? ev.Capacity,
                price: dto.Price ?? ev.Price,
                isOnline: dto.IsOnline ?? ev.IsOnline,
                isFeatured: ev.IsFeatured,
                tags: dto.Tags ?? ev.Tags,
                externalUrl: dto.ExternalUrl ?? ev.ExternalUrl,
                externalSource: ev.ExternalSource,
                externalId: ev.ExternalId,
                accessibilityInfo: dto.AccessibilityInfo ?? ev.AccessibilityInfo,
                promoterName: dto.PromoterName ?? ev.PromoterName,
                locale: dto.Locale ?? ev.Locale
            );

            await _eventRepository.UpdateAsync(ev);

            await _publishEndpoint.Publish(new EventUpdatedMessage(
                ev.EventId,
                ev.Title,
                ev.OrganizerId,
                ev.StartDateTime,
                ev.EndDateTime,
                null,
                DateTime.UtcNow
            ));

            var updated = await _eventRepository.GetByIdWithDetailsAsync(eventId) ?? ev;
            return ServiceResult<EventResponseDto>.Ok(MapToDto(updated));
        }
        catch (InvalidEventDataException ex)
        {
            return ServiceResult<EventResponseDto>.Fail(ex.Message);
        }
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

        if (string.IsNullOrWhiteSpace(ev.Title))
            return ServiceResult<bool>.Fail("Event title is required.");

        if (string.IsNullOrWhiteSpace(ev.Description))
            return ServiceResult<bool>.Fail("Event description is required.");

        if (ev.StartDateTime <= DateTime.UtcNow)
            return ServiceResult<bool>.Fail("Start date must be in the future.");

        if (ev.EndDateTime <= ev.StartDateTime)
            return ServiceResult<bool>.Fail("End date must be after start date.");

        ev.Publish();
        await _eventRepository.UpdateAsync(ev);

        await _publishEndpoint.Publish(new EventUpdatedMessage(
            ev.EventId,
            ev.Title,
            ev.OrganizerId,
            ev.StartDateTime,
            ev.EndDateTime,
            "Event published",
            DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId, string reason = "Cancelled by organizer")
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        ev.Cancel();
        await _eventRepository.UpdateAsync(ev);

        await _publishEndpoint.Publish(new EventCancelledMessage(
            ev.EventId,
            ev.Title,
            ev.OrganizerId,
            DateTime.UtcNow,
            reason));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> CompleteAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        ev.Complete();
        await _eventRepository.UpdateAsync(ev);

        await _publishEndpoint.Publish(new EventUpdatedMessage(
            ev.EventId,
            ev.Title,
            ev.OrganizerId,
            ev.StartDateTime,
            ev.EndDateTime,
            "Event completed",
            DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> LikeAsync(int eventId, int userId)
    {
        var ev = await _eventRepository.GetByIdWithDetailsAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.Status != EventStatus.Confirmed)
            return ServiceResult<bool>.Fail("Only active events can be liked.");

        if (await _eventRepository.IsLikedByUserAsync(eventId, userId))
            return ServiceResult<bool>.Conflict("Event already liked.");

        await _eventRepository.LikeAsync(eventId, userId);

        if (ev.OrganizerId != userId)
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
            profiles.TryGetValue(userId, out var liker);

            await _publishEndpoint.Publish(new EventLikedMessage(
                ev.EventId,
                ev.Title,
                ResolveEventImageUrl(ev),
                ev.OrganizerId,
                userId,
                ResolveDisplayName(liker, userId),
                liker?.AvatarUrl,
                DateTime.UtcNow
            ));
        }

        await _publishEndpoint.Publish(new UserEventPreferenceInteractionMessage(
            Guid.NewGuid(),
            userId,
            ev.EventId,
            ev.SegmentId,
            ev.GenreId,
            ev.SubGenreId,
            "Like",
            DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> UnlikeAsync(int eventId, int userId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (!await _eventRepository.IsLikedByUserAsync(eventId, userId))
            return ServiceResult<bool>.NotFound("You have not liked this event.");

        await _eventRepository.UnlikeAsync(eventId, userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> AddImageAsync(int eventId, string imageUrl, bool isCover, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        try
        {
            await _eventRepository.AddImageAsync(new EventImage(eventId, imageUrl, isCover));

            if (isCover)
            {
                var latestImageId = (await _eventRepository.GetEventImagesAsync(eventId))
                    .OrderByDescending(i => i.ImageId)
                    .First()
                    .ImageId;

                await _eventRepository.SetCoverImageAsync(eventId, latestImageId);
            }

            return ServiceResult<bool>.Ok(true);
        }
        catch (InvalidEventImageException ex)
        {
            return ServiceResult<bool>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId)
    {
        var image = await _eventRepository.GetImageAsync(imageId);
        if (image is null)
            return ServiceResult<bool>.NotFound("Image not found.");

        var ev = await _eventRepository.GetByIdAsync(image.EventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {image.EventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        await _eventRepository.DeleteImageAsync(imageId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> SetCoverImageAsync(int eventId, int imageId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        var image = await _eventRepository.GetImageAsync(imageId);
        if (image is null || image.EventId != eventId)
            return ServiceResult<bool>.NotFound("Image not found for this event.");

        await _eventRepository.SetCoverImageAsync(eventId, imageId);
        return ServiceResult<bool>.Ok(true);
    }

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

    public async Task<ServiceResult<SegmentResponseDto>> CreateSegmentAsync(CreateSegmentDto dto)
    {
        try
        {
            var segment = new Segment(dto.Name, dto.IconUrl, dto.Color);
            if (!dto.IsActive)
                segment.Deactivate();

            var created = await _eventRepository.CreateSegmentAsync(segment);
            return ServiceResult<SegmentResponseDto>.Created(MapSegment(created));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<SegmentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<SegmentResponseDto>> UpdateSegmentAsync(int segmentId, UpdateSegmentDto dto)
    {
        var segment = await _eventRepository.GetSegmentByIdAsync(segmentId);
        if (segment is null)
            return ServiceResult<SegmentResponseDto>.NotFound("Segment not found.");

        try
        {
            segment.Update(
                dto.Name ?? segment.Name,
                dto.IconUrl ?? segment.IconUrl,
                dto.Color ?? segment.Color
            );

            if (dto.IsActive.HasValue)
            {
                if (dto.IsActive.Value) segment.Activate();
                else segment.Deactivate();
            }

            await _eventRepository.UpdateSegmentAsync(segment);
            return ServiceResult<SegmentResponseDto>.Ok(MapSegment(segment));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<SegmentResponseDto>.Fail(ex.Message);
        }
    }

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

    public async Task<ServiceResult<GenreResponseDto>> CreateGenreAsync(CreateGenreDto dto)
    {
        var segment = await _eventRepository.GetSegmentByIdAsync(dto.SegmentId);
        if (segment is null)
            return ServiceResult<GenreResponseDto>.NotFound("Segment not found.");

        try
        {
            var genre = new Genre(dto.SegmentId, dto.Name);
            if (!dto.IsActive)
                genre.Deactivate();

            var created = await _eventRepository.CreateGenreAsync(genre);
            var createdWithDetails = await _eventRepository.GetGenreByIdAsync(created.GenreId);

            return ServiceResult<GenreResponseDto>.Created(MapGenre(createdWithDetails ?? created));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<GenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<GenreResponseDto>> UpdateGenreAsync(int genreId, UpdateGenreDto dto)
    {
        var genre = await _eventRepository.GetGenreByIdAsync(genreId);
        if (genre is null)
            return ServiceResult<GenreResponseDto>.NotFound("Genre not found.");

        var targetSegmentId = dto.SegmentId ?? genre.SegmentId;

        var segment = await _eventRepository.GetSegmentByIdAsync(targetSegmentId);
        if (segment is null)
            return ServiceResult<GenreResponseDto>.NotFound("Segment not found.");

        try
        {
            genre.Update(dto.Name ?? genre.Name, targetSegmentId);

            if (dto.IsActive.HasValue)
            {
                if (dto.IsActive.Value) genre.Activate();
                else genre.Deactivate();
            }

            await _eventRepository.UpdateGenreAsync(genre);
            var updated = await _eventRepository.GetGenreByIdAsync(genreId);

            return ServiceResult<GenreResponseDto>.Ok(MapGenre(updated ?? genre));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<GenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId)
    {
        var subGenres = await _eventRepository.GetSubGenresByGenreAsync(genreId);
        return ServiceResult<List<SubGenreResponseDto>>.Ok(subGenres.Select(MapSubGenre).ToList());
    }

    public async Task<ServiceResult<SubGenreResponseDto>> GetSubGenreByIdAsync(int subGenreId)
    {
        var subGenre = await _eventRepository.GetSubGenreByIdAsync(subGenreId);
        if (subGenre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Subgenre not found.");

        return ServiceResult<SubGenreResponseDto>.Ok(MapSubGenre(subGenre));
    }

    public async Task<ServiceResult<SubGenreResponseDto>> CreateSubGenreAsync(CreateSubGenreDto dto)
    {
        var genre = await _eventRepository.GetGenreByIdAsync(dto.GenreId);
        if (genre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Genre not found.");

        try
        {
            var subGenre = new SubGenre(dto.GenreId, dto.Name);
            if (!dto.IsActive)
                subGenre.Deactivate();

            var created = await _eventRepository.CreateSubGenreAsync(subGenre);
            return ServiceResult<SubGenreResponseDto>.Created(MapSubGenre(created));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<SubGenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<SubGenreResponseDto>> UpdateSubGenreAsync(int subGenreId, UpdateSubGenreDto dto)
    {
        var subGenre = await _eventRepository.GetSubGenreByIdAsync(subGenreId);
        if (subGenre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Subgenre not found.");

        var targetGenreId = dto.GenreId ?? subGenre.GenreId;

        var genre = await _eventRepository.GetGenreByIdAsync(targetGenreId);
        if (genre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Genre not found.");

        try
        {
            subGenre.Update(dto.Name ?? subGenre.Name, targetGenreId);

            if (dto.IsActive.HasValue)
            {
                if (dto.IsActive.Value) subGenre.Activate();
                else subGenre.Deactivate();
            }

            await _eventRepository.UpdateSubGenreAsync(subGenre);
            return ServiceResult<SubGenreResponseDto>.Ok(MapSubGenre(subGenre));
        }
        catch (InvalidReferenceDataException ex)
        {
            return ServiceResult<SubGenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<PagedResult<BookmarkResponseDto>>> GetUserBookmarksAsync(
        int userId,
        BookmarkFilterDto filter)
    {
        filter ??= new BookmarkFilterDto();

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 50);

        var pagedBookmarks = await _eventRepository.GetUserBookmarksAsync(userId, page, pageSize);

        return ServiceResult<PagedResult<BookmarkResponseDto>>.Ok(
            new PagedResult<BookmarkResponseDto>
            {
                Items = pagedBookmarks.Items.Select(MapBookmark).ToList(),
                TotalCount = pagedBookmarks.TotalCount,
                Page = pagedBookmarks.Page,
                PageSize = pagedBookmarks.PageSize
            });
    }


    public async Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId)
    {
        var existing = await _eventRepository.GetBookmarkByUserAndEventAsync(userId, dto.EventId);
        if (existing is not null)
            return ServiceResult<BookmarkResponseDto>.Conflict("Event already bookmarked.");

        var ev = await _eventRepository.GetByIdWithDetailsAsync(dto.EventId);
        if (ev is null)
            return ServiceResult<BookmarkResponseDto>.NotFound("Event not found.");

        try
        {
            var bookmark = new Bookmark(dto.EventId, userId, dto.Memo);
            var created = await _eventRepository.CreateBookmarkAsync(bookmark);

            if (ev.OrganizerId != userId)
            {
                var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
                profiles.TryGetValue(userId, out var saver);

                await _publishEndpoint.Publish(new EventBookmarkedMessage(
                    ev.EventId,
                    ev.Title,
                    ResolveEventImageUrl(ev),
                    ev.OrganizerId,
                    userId,
                    ResolveDisplayName(saver, userId),
                    saver?.AvatarUrl,
                    DateTime.UtcNow
                ));
            }

            await _publishEndpoint.Publish(new UserEventPreferenceInteractionMessage(
                Guid.NewGuid(),
                userId,
                ev.EventId,
                ev.SegmentId,
                ev.GenreId,
                ev.SubGenreId,
                "Bookmark",
                DateTime.UtcNow));

            var createdWithEvent = await _eventRepository.GetBookmarkByIdAsync(created.BookmarkId) ?? created;
            return ServiceResult<BookmarkResponseDto>.Created(MapBookmark(createdWithEvent));
        }
        catch (InvalidBookmarkException ex)
        {
            return ServiceResult<BookmarkResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<BookmarkResponseDto>> UpdateBookmarkAsync(int bookmarkId, UpdateBookmarkDto dto, int userId)
    {
        var bookmark = await _eventRepository.GetBookmarkByIdAsync(bookmarkId);
        if (bookmark is null)
            return ServiceResult<BookmarkResponseDto>.NotFound("Bookmark not found.");

        if (bookmark.UserId != userId)
            return ServiceResult<BookmarkResponseDto>.Forbidden("Not your bookmark.");

        bookmark.UpdateMemo(dto.Memo);
        await _eventRepository.UpdateBookmarkAsync(bookmark);

        return ServiceResult<BookmarkResponseDto>.Ok(MapBookmark(bookmark));
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

    public async Task<ServiceResult<CommentResponseDto>> GetCommentByIdAsync(int commentId, int? requesterId = null)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null || comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        var mapped = MapComment(comment);
        await EnrichCommentsAsync(new List<CommentResponseDto> { mapped }, requesterId);

        return ServiceResult<CommentResponseDto>.Ok(mapped);
    }

    public async Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId)
    {
        Comment? parent = null;

        if (dto.ParentCommentId.HasValue)
        {
            parent = await _eventRepository.GetCommentByIdAsync(dto.ParentCommentId.Value);
            if (parent is null)
                return ServiceResult<CommentResponseDto>.NotFound($"Parent comment {dto.ParentCommentId.Value} not found.");
        }

        try
        {
            var comment = new Comment(userId, dto.EventId, dto.Content, dto.ParentCommentId);
            var created = await _eventRepository.CreateCommentAsync(comment);
            var dtoResult = MapComment(created);

            await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

            var ev = await _eventRepository.GetByIdWithDetailsAsync(dto.EventId);
            if (ev is not null)
            {
                var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
                profiles.TryGetValue(userId, out var actor);

                var actorDisplayName = ResolveDisplayName(actor, userId);
                var actorAvatarUrl = actor?.AvatarUrl;
                var eventImageUrl = ResolveEventImageUrl(ev);
                var preview = BuildPreview(created.Content);

                if (dto.ParentCommentId.HasValue)
                {
                    if (parent is not null && parent.UserId != userId)
                    {
                        await _publishEndpoint.Publish(new EventCommentReplyCreatedMessage(
                            ev.EventId,
                            ev.Title,
                            eventImageUrl,
                            parent.CommentId,
                            parent.UserId,
                            created.CommentId,
                            userId,
                            actorDisplayName,
                            actorAvatarUrl,
                            preview,
                            DateTime.UtcNow
                        ));
                    }
                }
                else
                {
                    if (ev.OrganizerId != userId)
                    {
                        await _publishEndpoint.Publish(new EventCommentCreatedMessage(
                            ev.EventId,
                            ev.Title,
                            eventImageUrl,
                            ev.OrganizerId,
                            created.CommentId,
                            userId,
                            actorDisplayName,
                            actorAvatarUrl,
                            preview,
                            DateTime.UtcNow
                        ));
                    }
                }

                await _publishEndpoint.Publish(new UserEventPreferenceInteractionMessage(
                    Guid.NewGuid(),
                    userId,
                    ev.EventId,
                    ev.SegmentId,
                    ev.GenreId,
                    ev.SubGenreId,
                    "Comment",
                    DateTime.UtcNow));
            }

            return ServiceResult<CommentResponseDto>.Ok(dtoResult);
        }
        catch (InvalidCommentException ex)
        {
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        if (comment.UserId != userId)
            return ServiceResult<CommentResponseDto>.Forbidden("Not your comment.");

        try
        {
            comment.Edit(dto.Content);
            await _eventRepository.UpdateCommentAsync(comment);

            var dtoResult = MapComment(comment);
            await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

            return ServiceResult<CommentResponseDto>.Ok(dtoResult);
        }
        catch (InvalidCommentException ex)
        {
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
        catch (CommentAlreadyDeletedException ex)
        {
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
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

    public async Task<ServiceResult<bool>> LikeCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");

        if (comment.IsDeleted)
            return ServiceResult<bool>.Fail("Comment has been deleted.");

        if (await _eventRepository.IsCommentLikedByUserAsync(commentId, userId))
            return ServiceResult<bool>.Conflict("Comment already liked.");

        await _eventRepository.LikeCommentAsync(commentId, userId);

        if (comment.UserId != userId)
        {
            var ev = await _eventRepository.GetByIdWithDetailsAsync(comment.EventId);
            if (ev is not null)
            {
                var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
                profiles.TryGetValue(userId, out var liker);

                await _publishEndpoint.Publish(new EventCommentLikedMessage(
                    ev.EventId,
                    ev.Title,
                    ResolveEventImageUrl(ev),
                    comment.CommentId,
                    comment.UserId,
                    userId,
                    ResolveDisplayName(liker, userId),
                    liker?.AvatarUrl,
                    BuildPreview(comment.Content),
                    DateTime.UtcNow
                ));
            }
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> UnlikeCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");

        await _eventRepository.UnlikeCommentAsync(commentId, userId);
        return ServiceResult<bool>.Ok(true);
    }

    private async Task EnrichCommentsAsync(List<CommentResponseDto> comments, int? requesterId)
    {
        var allComments = FlattenComments(comments).ToList();

        var userIds = allComments
            .Where(x => !x.IsDeleted && x.UserId.HasValue)
            .Select(x => x.UserId!.Value)
            .Distinct()
            .ToList();

        var profiles = await _userProfileService.GetProfilesByIdsAsync(userIds);

        foreach (var comment in allComments)
        {
            if (comment.IsDeleted || !comment.UserId.HasValue)
            {
                comment.Username = null;
                comment.DisplayName = null;
                comment.AvatarUrl = null;
                comment.IsLiked = false;
                continue;
            }

            if (profiles.TryGetValue(comment.UserId.Value, out var profile))
            {
                comment.Username = profile.Username;
                comment.DisplayName = profile.DisplayName;
                comment.AvatarUrl = profile.AvatarUrl;
            }

            comment.IsLiked = requesterId.HasValue &&
                             await _eventRepository.IsCommentLikedByUserAsync(comment.CommentId, requesterId.Value);
        }
    }

    private static CommentResponseDto MapComment(Comment c, bool includeReplies = false)
    {
        var visibleReplies = includeReplies
            ? c.Replies
                .Where(r => !r.IsDeleted)
                .Select(r => MapComment(r, includeReplies: true))
                .ToList()
            : new List<CommentResponseDto>();

        return new CommentResponseDto
        {
            CommentId = c.CommentId,
            Content = c.IsDeleted ? "[deleted]" : c.Content,
            LikesCount = c.LikesCount,
            UserId = c.IsDeleted ? null : c.UserId,
            EventId = c.EventId,
            CreatedAt = c.CreatedAt,
            UpdatedAt = c.UpdatedAt,
            IsDeleted = c.IsDeleted,
            IsReply = c.IsReply,
            ParentCommentId = c.ParentCommentId,
            ReplyCount = c.Replies?.Count(r => !r.IsDeleted) ?? 0,
            Replies = visibleReplies,
            Username = null,
            DisplayName = null,
            AvatarUrl = null,
            IsLiked = false
        };
    }

    private static IEnumerable<CommentResponseDto> FlattenComments(IEnumerable<CommentResponseDto> comments)
    {
        foreach (var comment in comments)
        {
            yield return comment;

            foreach (var reply in FlattenComments(comment.Replies))
                yield return reply;
        }
    }

    private static CommentResponseDto MapComment(Comment c)
    {
        var visibleReplies = c.Replies
            .Where(r => !r.IsDeleted)
            .Select(MapComment)
            .ToList();

        return new CommentResponseDto
        {
            CommentId = c.CommentId,
            Content = c.IsDeleted ? "[deleted]" : c.Content,
            LikesCount = c.LikesCount,
            UserId = c.IsDeleted ? null : c.UserId,
            EventId = c.EventId,
            CreatedAt = c.CreatedAt,
            UpdatedAt = c.UpdatedAt,
            IsDeleted = c.IsDeleted,
            IsReply = c.IsReply,
            ParentCommentId = c.ParentCommentId,
            ReplyCount = c.Replies.Count(r => !r.IsDeleted),
            Replies = visibleReplies,
            Username = null,
            DisplayName = null,
            AvatarUrl = null,
            IsLiked = false
        };
    }

    private static double CalculatePreferenceScore(
        DomainEvent ev,
        IReadOnlyList<UserPreferenceDto> preferences)
    {
        double score = 0;

        var segmentScore = preferences
            .Where(p =>
                p.SegmentId == ev.SegmentId &&
                p.GenreId == null &&
                p.SubGenreId == null)
            .Select(p => p.Score)
            .FirstOrDefault();

        var genreScore = preferences
            .Where(p =>
                p.SegmentId == ev.SegmentId &&
                p.GenreId == ev.GenreId &&
                p.SubGenreId == null)
            .Select(p => p.Score)
            .FirstOrDefault();

        var subGenreScore = preferences
            .Where(p =>
                p.SegmentId == ev.SegmentId &&
                p.GenreId == ev.GenreId &&
                p.SubGenreId == ev.SubGenreId)
            .Select(p => p.Score)
            .FirstOrDefault();

        score += segmentScore * 1.0;
        score += genreScore * 2.0;
        score += subGenreScore * 3.0;

        if (ev.IsFeatured)
            score += 0.5;

        return score;
    }

    private static EventResponseDto MapToDto(DomainEvent ev, bool isLiked = false) => new()
    {
        EventId = ev.EventId,
        OrganizerId = ev.OrganizerId,
        SegmentId = ev.SegmentId,
        SegmentName = ev.Segment?.Name,
        SegmentColor = ev.Segment?.Color,
        GenreId = ev.GenreId,
        GenreName = ev.Genre?.Name,
        SubGenreId = ev.SubGenreId,
        SubGenreName = ev.SubGenre?.Name,
        Title = ev.Title,
        Description = ev.Description,
        Latitude = ev.Latitude,
        Longitude = ev.Longitude,
        StartDateTime = ev.StartDateTime,
        EndDateTime = ev.EndDateTime,
        Capacity = ev.Capacity,
        Price = ev.Price,
        Status = ev.Status.ToString(),
        IsFeatured = ev.IsFeatured,
        ViewCount = ev.ViewCount,
        LikesCount = ev.LikesCount,
        IsLiked = isLiked,
        Tags = ev.Tags,
        AccessibilityInfo = ev.AccessibilityInfo,
        PromoterName = ev.PromoterName,
        Locale = ev.Locale,
        CreatedAt = ev.CreatedAt,
        UpdatedAt = ev.UpdatedAt,
        ImageUrls = ev.Images
            .Select(i => i.ImageUrl)
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .ToList(),
        CoverImageUrl = ev.Images
            .FirstOrDefault(i => i.IsCover)?.ImageUrl,
        Images = ev.Images
            .Select(i => new EventImageResponseDto
            {
                ImageId = i.ImageId,
                ImageUrl = i.ImageUrl,
                IsCover = i.IsCover,
                UploadedAt = i.UploadedAt
            })
            .ToList()
    };

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
        SegmentName = g.Segment?.Name,
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

    private static BookmarkResponseDto MapBookmark(Bookmark b) => new()
    {
        BookmarkId = b.BookmarkId,
        ImageUrl = b.Event?.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
                   ?? b.Event?.Images.FirstOrDefault()?.ImageUrl
                   ?? string.Empty,
        SavedAt = b.SavedAt,
        Memo = b.Memo,
        EventId = b.EventId,
        UserId = b.UserId
    };

    private static IEnumerable<int> GetCommentTreeUserIds(Comment comment)
    {
        if (!comment.IsDeleted)
            yield return comment.UserId;

        foreach (var reply in comment.Replies)
        {
            foreach (var id in GetCommentTreeUserIds(reply))
                yield return id;
        }
    }

    private static string ResolveDisplayName(CommentUserProfileDto? profile, int userId)
    {
        if (!string.IsNullOrWhiteSpace(profile?.Username))
            return profile!.Username!;

        if (!string.IsNullOrWhiteSpace(profile?.DisplayName))
            return profile!.DisplayName!;

        return $"User {userId}";
    }

    private static string? ResolveEventImageUrl(DomainEvent ev)
    {
        return ev.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
            ?? ev.Images.FirstOrDefault()?.ImageUrl;
    }

    private static string BuildPreview(string? content, int maxLength = 120)
    {
        if (string.IsNullOrWhiteSpace(content))
            return string.Empty;

        var normalized = content.Trim();
        return normalized.Length <= maxLength
            ? normalized
            : normalized[..maxLength];
    }
}