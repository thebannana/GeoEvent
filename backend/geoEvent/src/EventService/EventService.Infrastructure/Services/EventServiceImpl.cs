using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Domain.Entities;
using EventService.Domain.Enums;
using EventService.Infrastructure.Repositories;
using MassTransit;
using MassTransit.Transports;
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

    public async Task<ServiceResult<List<CommentResponseDto>>> GetEventCommentsAsync(int eventId, int? requesterId = null)
    {
        var comments = await _eventRepository.GetEventCommentsAsync(eventId);
        var mapped = comments.Select(MapComment).ToList();

        await EnrichCommentsAsync(mapped, requesterId);

        return ServiceResult<List<CommentResponseDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<List<CommentResponseDto>>> GetRepliesAsync(int commentId, int? requesterId = null)
    {
        var replies = await _eventRepository.GetRepliesAsync(commentId);
        var mapped = replies.Select(MapComment).ToList();

        await EnrichCommentsAsync(mapped, requesterId);

        return ServiceResult<List<CommentResponseDto>>.Ok(mapped);
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
        var dtoResult = MapComment(created);
        await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

        var ev = await _eventRepository.GetByIdWithDetailsAsync(dto.EventId);
        if (ev != null)
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
            profiles.TryGetValue(userId, out var actor);

            var actorDisplayName = ResolveDisplayName(actor, userId);
            var actorAvatarUrl = actor?.AvatarUrl;
            var eventImageUrl = ResolveEventImageUrl(ev);
            var preview = BuildPreview(created.Content);

            if (dto.ParentCommentId.HasValue)
            {
                if (parent?.UserId.HasValue == true && parent.UserId.Value != userId)
                {
                    await _publishEndpoint.Publish(new EventCommentReplyCreatedMessage(
                        ev.EventId,
                        ev.Title,
                        eventImageUrl,
                        parent.CommentId,
                        parent.UserId.Value,
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
                if (ev.OrganizerId.HasValue && ev.OrganizerId.Value != userId)
                {
                    await _publishEndpoint.Publish(new EventCommentCreatedMessage(
                        ev.EventId,
                        ev.Title,
                        eventImageUrl,
                        ev.OrganizerId.Value,
                        created.CommentId,
                        userId,
                        actorDisplayName,
                        actorAvatarUrl,
                        preview,
                        DateTime.UtcNow
                    ));
                }
            }
        }

        if (ev is not null)
        {
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

    public async Task<ServiceResult<CommentResponseDto>> GetCommentByIdAsync(int commentId, int? requesterId = null)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null || comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        var mapped = MapComment(comment);
        await EnrichCommentsAsync(new List<CommentResponseDto> { mapped }, requesterId);

        return ServiceResult<CommentResponseDto>.Ok(mapped);
    }
    public async Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        if (comment.UserId != userId)
            return ServiceResult<CommentResponseDto>.Forbidden("Not your comment.");

        if (comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.Fail("Comment has been deleted.");

        comment.Content = dto.Content;
        comment.UpdatedAt = DateTime.UtcNow;

        await _eventRepository.UpdateCommentAsync(comment);

        var dtoResult = MapComment(comment);
        await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

        return ServiceResult<CommentResponseDto>.Ok(dtoResult);
    }

    public async Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");

        if (comment.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your comment.");

        comment.Delete();
        comment.Content = "[deleted]";

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

        if (comment.UserId.HasValue && comment.UserId.Value != userId)
        {
            var ev = await _eventRepository.GetByIdWithDetailsAsync(comment.EventId ?? 0);
            if (ev != null)
            {
                var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
                profiles.TryGetValue(userId, out var liker);

                await _publishEndpoint.Publish(new EventCommentLikedMessage(
                    ev.EventId,
                    ev.Title,
                    ResolveEventImageUrl(ev),
                    comment.CommentId,
                    comment.UserId.Value,
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
        var visibleReplies = c.Replies?
            .Where(r => !r.IsDeleted)
            .Select(MapComment)
            .ToList() ?? new List<CommentResponseDto>();

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
            IsReply = c.ParentCommentId.HasValue,
            ParentCommentId = c.ParentCommentId,
            ReplyCount = c.Replies?.Count(r => !r.IsDeleted) ?? 0,
            Replies = visibleReplies,
            Username = null,
            DisplayName = null,
            AvatarUrl = null,
            IsLiked = false
        };
    }
    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetPublicAsync(
    EventFilterDto filter,
    int? requesterId = null)
    {
        filter ??= new EventFilterDto();
        filter.Status = EventStatus.Active;
        filter.OrganizerId = null;

        if (!requesterId.HasValue)
        {
            var defaultResult = await _eventRepository.GetAllAsync(filter);

            return ServiceResult<PagedResult<EventResponseDto>>.Ok(new PagedResult<EventResponseDto>
            {
                Items = defaultResult.Items.Select(ev => MapToDto(ev, false)).ToList(),
                TotalCount = defaultResult.TotalCount,
                Page = defaultResult.Page,
                PageSize = defaultResult.PageSize
            });
        }

        var preferences = await _userProfileService.GetUserPreferencesAsync(requesterId.Value);

        if (preferences.Count == 0)
        {
            var defaultResult = await _eventRepository.GetAllAsync(filter);

            var itemsWithoutPrefs = new List<EventResponseDto>();
            foreach (var ev in defaultResult.Items)
            {
                var isLiked = await _eventRepository.IsLikedByUserAsync(ev.EventId, requesterId.Value);
                itemsWithoutPrefs.Add(MapToDto(ev, isLiked));
            }

            return ServiceResult<PagedResult<EventResponseDto>>.Ok(new PagedResult<EventResponseDto>
            {
                Items = itemsWithoutPrefs,
                TotalCount = defaultResult.TotalCount,
                Page = defaultResult.Page,
                PageSize = defaultResult.PageSize
            });
        }

        var candidates = await _eventRepository.GetPublicCandidatesAsync(filter, 200);

        var scored = new List<(DomainEvent Event, double Score)>();

        foreach (var ev in candidates)
        {
            var score = CalculatePreferenceScore(ev, preferences);
            scored.Add((ev, score));
        }

        var ranked = scored
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Event.StartDateTime)
            .ThenByDescending(x => x.Event.LikesCount)
            .ThenBy(x => x.Event.EventId)
            .ToList();

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 20 : Math.Min(filter.PageSize, 100);

        var pagedItems = ranked
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var resultItems = new List<EventResponseDto>();

        foreach (var item in pagedItems)
        {
            var isLiked = await _eventRepository.IsLikedByUserAsync(item.Event.EventId, requesterId.Value);
            resultItems.Add(MapToDto(item.Event, isLiked));
        }

        return ServiceResult<PagedResult<EventResponseDto>>.Ok(new PagedResult<EventResponseDto>
        {
            Items = resultItems,
            TotalCount = ranked.Count,
            Page = page,
            PageSize = pageSize
        });
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

    public async Task<ServiceResult<EventResponseDto>> GetPublicByIdAsync(int eventId, int? requesterId = null)
    {
        var ev = await _eventRepository.GetByIdWithDetailsAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (ev.Status != EventStatus.Active && ev.OrganizerId != requesterId)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        if (!requesterId.HasValue || ev.OrganizerId != requesterId.Value)
        {
            await _eventRepository.IncrementViewCountAsync(eventId);
            ev.ViewCount++;
        }

        var isLiked = false;
        if (requesterId.HasValue)
            isLiked = await _eventRepository.IsLikedByUserAsync(eventId, requesterId.Value);

        return ServiceResult<EventResponseDto>.Ok(MapToDto(ev, isLiked));
    }

    public async Task<ServiceResult<List<LikedEventResponseDto>>> GetLikedEventsAsync(int userId)
    {
        var likes = await _eventRepository.GetLikedEventsByUserAsync(userId);

        var items = likes
            .Where(x => x.EventId.HasValue)
            .Select(x => new LikedEventResponseDto
            {
                EventId = x.EventId!.Value,
                Title = x.Event?.Title ?? $"Event #{x.EventId!.Value}",
                ImageUrl = x.Event?.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
                           ?? x.Event?.Images.FirstOrDefault()?.ImageUrl,
                LikedAt = x.LikedAt,
                IsLiked = true
            })
            .ToList();

        return ServiceResult<List<LikedEventResponseDto>>.Ok(items);
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
            .Where(e => e.Status == EventStatus.Active)
            .Select(e => MapToDto(e, false))
            .ToList();

        return ServiceResult<List<EventResponseDto>>.Ok(publicEvents);
    }

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetMyDraftsAsync(EventFilterDto filter, int requesterId)
    {
        filter ??= new EventFilterDto();
        filter.OrganizerId = requesterId;
        filter.Status = EventStatus.Draft;

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

    public async Task<ServiceResult<EventResponseDto>> CreateAsync(CreateEventDto dto, int organizerId)
    {
        if (dto.StartDateTime <= DateTime.UtcNow)
            return ServiceResult<EventResponseDto>.Fail("Start date must be in the future.");

        if (dto.EndDateTime <= dto.StartDateTime)
            return ServiceResult<EventResponseDto>.Fail("End date must be after start date.");

        _logger.LogInformation(
            "CreateAsync received event create request. Title={Title}, Capacity={Capacity}, Price={Price}, Start={Start}, End={End}, OrganizerId={OrganizerId}",
            dto.Title,
            dto.Capacity,
            dto.Price,
            dto.StartDateTime,
            dto.EndDateTime,
            organizerId);

        var entity = new DomainEvent
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

        _logger.LogInformation(
            "Event created in EventService. EventId={EventId}, Capacity={Capacity}, Price={Price}",
            created.EventId,
            created.Capacity,
            created.Price);

        await _publishEndpoint.Publish(new EventCreatedMessage(
            created.EventId,
            created.Title,
            created.CityId,
            created.OrganizerId,
            created.SegmentId,
            created.GenreId,
            created.SubGenreId,
            created.VenueId,
            created.Price,
            created.Price == 0,
            created.Capacity,
            created.StartDateTime,
            created.EndDateTime,
            DateTime.UtcNow));

        return ServiceResult<EventResponseDto>.Created(MapToDto(created));
    }

    public async Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId)
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

        var effectiveStart = dto.StartDateTime ?? ev.StartDateTime;
        var effectiveEnd = dto.EndDateTime ?? ev.EndDateTime;

        if (effectiveEnd <= effectiveStart)
            return ServiceResult<EventResponseDto>.Fail("End date must be after start date.");

        await _eventRepository.UpdateAsync(ev);

        await _publishEndpoint.Publish(new EventUpdatedMessage(
            ev.EventId,
            ev.Title,
            ev.OrganizerId,
            ev.StartDateTime,
            ev.EndDateTime,
            null,
            DateTime.UtcNow));

        var updated = await _eventRepository.GetByIdWithDetailsAsync(eventId) ?? ev;
        return ServiceResult<EventResponseDto>.Ok(MapToDto(updated));
    }

    public async Task<ServiceResult<SegmentResponseDto>> CreateSegmentAsync(CreateSegmentDto dto)
    {
        var segment = new Segment
        {
            Name = dto.Name,
            IconUrl = dto.IconUrl,
            Color = dto.Color,
            IsActive = dto.IsActive
        };

        var created = await _eventRepository.CreateSegmentAsync(segment);
        return ServiceResult<SegmentResponseDto>.Created(MapSegment(created));
    }

    public async Task<ServiceResult<SubGenreResponseDto>> GetSubGenreByIdAsync(int subGenreId)
    {
        var subGenre = await _eventRepository.GetSubGenreByIdAsync(subGenreId);
        if (subGenre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Subgenre not found.");

        return ServiceResult<SubGenreResponseDto>.Ok(MapSubGenre(subGenre));
    }

    public async Task<ServiceResult<SegmentResponseDto>> UpdateSegmentAsync(int segmentId, UpdateSegmentDto dto)
    {
        var segment = await _eventRepository.GetSegmentByIdAsync(segmentId);
        if (segment is null)
            return ServiceResult<SegmentResponseDto>.NotFound("Segment not found.");

        if (dto.Name is not null)
            segment.Name = dto.Name;

        if (dto.IconUrl is not null)
            segment.IconUrl = dto.IconUrl;

        if (dto.Color is not null)
            segment.Color = dto.Color;

        if (dto.IsActive.HasValue)
            segment.IsActive = dto.IsActive.Value;

        await _eventRepository.UpdateSegmentAsync(segment);
        return ServiceResult<SegmentResponseDto>.Ok(MapSegment(segment));
    }

    public async Task<ServiceResult<GenreResponseDto>> CreateGenreAsync(CreateGenreDto dto)
    {
        var segment = await _eventRepository.GetSegmentByIdAsync(dto.SegmentId);
        if (segment is null)
            return ServiceResult<GenreResponseDto>.NotFound("Segment not found.");

        var genre = new Genre
        {
            Name = dto.Name,
            SegmentId = dto.SegmentId,
            IsActive = dto.IsActive
        };

        var created = await _eventRepository.CreateGenreAsync(genre);
        var createdWithDetails = await _eventRepository.GetGenreByIdAsync(created.GenreId);
        return ServiceResult<GenreResponseDto>.Created(MapGenre(createdWithDetails ?? created));
    }

    public async Task<ServiceResult<GenreResponseDto>> UpdateGenreAsync(int genreId, UpdateGenreDto dto)
    {
        var genre = await _eventRepository.GetGenreByIdAsync(genreId);
        if (genre is null)
            return ServiceResult<GenreResponseDto>.NotFound("Genre not found.");

        if (dto.SegmentId.HasValue)
        {
            var segment = await _eventRepository.GetSegmentByIdAsync(dto.SegmentId.Value);
            if (segment is null)
                return ServiceResult<GenreResponseDto>.NotFound("Segment not found.");

            genre.SegmentId = dto.SegmentId.Value;
        }

        if (dto.Name is not null)
            genre.Name = dto.Name;

        if (dto.IsActive.HasValue)
            genre.IsActive = dto.IsActive.Value;

        await _eventRepository.UpdateGenreAsync(genre);

        var updated = await _eventRepository.GetGenreByIdAsync(genreId);
        return ServiceResult<GenreResponseDto>.Ok(MapGenre(updated ?? genre));
    }

    public async Task<ServiceResult<SubGenreResponseDto>> CreateSubGenreAsync(CreateSubGenreDto dto)
    {
        var genre = await _eventRepository.GetGenreByIdAsync(dto.GenreId);
        if (genre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Genre not found.");

        var subGenre = new SubGenre
        {
            Name = dto.Name,
            GenreId = dto.GenreId,
            IsActive = dto.IsActive
        };

        var created = await _eventRepository.CreateSubGenreAsync(subGenre);
        return ServiceResult<SubGenreResponseDto>.Created(MapSubGenre(created));
    }

    public async Task<ServiceResult<SubGenreResponseDto>> UpdateSubGenreAsync(int subGenreId, UpdateSubGenreDto dto)
    {
        var subGenre = await _eventRepository.GetSubGenreByIdAsync(subGenreId);
        if (subGenre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Subgenre not found.");

        if (dto.GenreId.HasValue)
        {
            var genre = await _eventRepository.GetGenreByIdAsync(dto.GenreId.Value);
            if (genre is null)
                return ServiceResult<SubGenreResponseDto>.NotFound("Genre not found.");

            subGenre.GenreId = dto.GenreId.Value;
        }

        if (dto.Name is not null)
            subGenre.Name = dto.Name;

        if (dto.IsActive.HasValue)
            subGenre.IsActive = dto.IsActive.Value;

        await _eventRepository.UpdateSubGenreAsync(subGenre);
        return ServiceResult<SubGenreResponseDto>.Ok(MapSubGenre(subGenre));
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

    public async Task<ServiceResult<bool>> PostponeAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        ev.Postpone();
        await _eventRepository.UpdateAsync(ev);

        await _publishEndpoint.Publish(new EventUpdatedMessage(
            ev.EventId,
            ev.Title,
            ev.OrganizerId,
            ev.StartDateTime,
            ev.EndDateTime,
            "Event postponed",
            DateTime.UtcNow));

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

        if (ev.Status != EventStatus.Active)
            return ServiceResult<bool>.Fail("Only active events can be liked.");

        if (await _eventRepository.IsLikedByUserAsync(eventId, userId))
            return ServiceResult<bool>.Conflict("Event already liked.");

        await _eventRepository.LikeAsync(eventId, userId);

        if (ev.OrganizerId.HasValue && ev.OrganizerId.Value != userId)
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
            profiles.TryGetValue(userId, out var liker);

            await _publishEndpoint.Publish(new EventLikedMessage(
                ev.EventId,
                ev.Title,
                ResolveEventImageUrl(ev),
                ev.OrganizerId.Value,
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

        await _eventRepository.AddImageAsync(new EventImage
        {
            EventId = eventId,
            ImageUrl = imageUrl,
            IsCover = isCover
        });

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

    public async Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId)
    {
        var image = await _eventRepository.GetImageAsync(imageId);
        if (image is null)
            return ServiceResult<bool>.NotFound("Image not found.");

        if (image.EventId is null)
            return ServiceResult<bool>.Fail("Image is not linked to an event.");

        var ev = await _eventRepository.GetByIdAsync(image.EventId.Value);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {image.EventId.Value} not found.");

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

    public async Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId)
    {
        var subGenres = await _eventRepository.GetSubGenresByGenreAsync(genreId);
        return ServiceResult<List<SubGenreResponseDto>>.Ok(subGenres.Select(MapSubGenre).ToList());
    }

    public async Task<ServiceResult<VenueResponseDto>> GetVenueByIdAsync(int venueId)
    {
        var venue = await _eventRepository.GetVenueByIdAsync(venueId);
        if (venue is null)
            return ServiceResult<VenueResponseDto>.NotFound("Venue not found.");

        return ServiceResult<VenueResponseDto>.Ok(MapVenue(venue));
    }

    public async Task<ServiceResult<List<VenueResponseDto>>> GetVenuesByCityAsync(int cityId)
    {
        var venues = await _eventRepository.GetVenuesByCityAsync(cityId);
        return ServiceResult<List<VenueResponseDto>>.Ok(venues.Select(MapVenue).ToList());
    }

    public async Task<ServiceResult<VenueResponseDto>> CreateVenueAsync(CreateVenueDto dto)
    {
        var venue = new Venue
        {
            Name = dto.Name,
            Address = dto.Address,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            CityId = dto.CityId,
            VenueType = dto.VenueType,
            WebsiteUrl = dto.WebsiteUrl,
            PhoneNumber = dto.PhoneNumber,
            Description = dto.Description,
            TimeZone = dto.TimeZone,
            Locale = dto.Locale
        };

        var created = await _eventRepository.CreateVenueAsync(venue);
        return ServiceResult<VenueResponseDto>.Created(MapVenue(created));
    }

    public async Task<ServiceResult<List<PriceZoneResponseDto>>> GetPriceZonesByVenueAsync(int venueId)
    {
        var zones = await _eventRepository.GetPriceZonesByVenueAsync(venueId);
        return ServiceResult<List<PriceZoneResponseDto>>.Ok(zones.Select(MapPriceZone).ToList());
    }

    public async Task<ServiceResult<PriceZoneResponseDto>> CreatePriceZoneAsync(CreatePriceZoneDto dto, int requesterId)
    {
        var venue = await _eventRepository.GetVenueByIdAsync(dto.VenueId);
        if (venue is null)
            return ServiceResult<PriceZoneResponseDto>.NotFound("Venue not found.");

        var priceZone = new PriceZone
        {
            VenueId = dto.VenueId,
            Name = dto.Name,
            Description = dto.Description,
            IsActive = true
        };

        var created = await _eventRepository.CreatePriceZoneAsync(priceZone);
        return ServiceResult<PriceZoneResponseDto>.Created(MapPriceZone(created));
    }

    public async Task<ServiceResult<List<BookmarkResponseDto>>> GetUserBookmarksAsync(int userId)
    {
        var bookmarks = await _eventRepository.GetUserBookmarksAsync(userId);
        return ServiceResult<List<BookmarkResponseDto>>.Ok(bookmarks.Select(MapBookmark).ToList());
    }

    public async Task<ServiceResult<BookmarkResponseDto>> CreateBookmarkAsync(CreateBookmarkDto dto, int userId)
    {
        var existing = await _eventRepository.GetBookmarkByUserAndEventAsync(userId, dto.EventId);
        if (existing is not null)
            return ServiceResult<BookmarkResponseDto>.Conflict("Event already bookmarked.");

        var ev = await _eventRepository.GetByIdWithDetailsAsync(dto.EventId);
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

        if (ev.OrganizerId.HasValue && ev.OrganizerId.Value != userId)
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(new[] { userId });
            profiles.TryGetValue(userId, out var saver);

            await _publishEndpoint.Publish(new EventBookmarkedMessage(
                ev.EventId,
                ev.Title,
                ResolveEventImageUrl(ev),
                ev.OrganizerId.Value,
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

        return ServiceResult<BookmarkResponseDto>.Created(MapBookmark(created));
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
        VenueId = ev.VenueId,
        VenueName = ev.Venue?.Name,
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
        IsLiked = isLiked,
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

    private async Task<CommentResponseDto> MapCommentAsync(
        Comment c,
        int? requesterId,
        IReadOnlyDictionary<int, CommentUserProfileDto> profiles)
    {
        var isLiked = false;

        if (requesterId.HasValue && !c.IsDeleted)
            isLiked = await _eventRepository.IsCommentLikedByUserAsync(c.CommentId, requesterId.Value);

        var replies = new List<CommentResponseDto>();

        foreach (var reply in c.Replies.Where(r => !r.IsDeleted))
        {
            replies.Add(await MapCommentAsync(reply, requesterId, profiles));
        }

        CommentUserProfileDto? profile = null;
        if (!c.IsDeleted && c.UserId.HasValue)
            profiles.TryGetValue(c.UserId.Value, out profile);

        return new CommentResponseDto
        {
            CommentId = c.CommentId,
            Content = c.IsDeleted ? "[deleted]" : c.Content,
            LikesCount = c.LikesCount,
            UserId = c.IsDeleted ? null : c.UserId,
            Username = c.IsDeleted ? null : profile?.Username,
            DisplayName = c.IsDeleted ? null : profile?.DisplayName,
            AvatarUrl = c.IsDeleted ? null : profile?.AvatarUrl,
            EventId = c.EventId ?? 0,
            CreatedAt = c.CreatedAt,
            UpdatedAt = c.UpdatedAt,
            IsDeleted = c.IsDeleted,
            IsReply = c.IsReply,
            ParentCommentId = c.ParentCommentId,
            ReplyCount = c.Replies.Count(r => !r.IsDeleted),
            Replies = replies,
            IsLiked = isLiked
        };
    }

    private async Task<IReadOnlyDictionary<int, CommentUserProfileDto>> LoadProfilesForCommentTreeAsync(IEnumerable<Comment> comments)
    {
        var userIds = comments
            .SelectMany(GetCommentTreeUserIds)
            .Distinct()
            .ToList();

        if (userIds.Count == 0)
            return new Dictionary<int, CommentUserProfileDto>();

        return await _userProfileService.GetProfilesByIdsAsync(userIds);
    }

    private static IEnumerable<int> GetCommentTreeUserIds(Comment comment)
    {
        if (!comment.IsDeleted && comment.UserId.HasValue)
            yield return comment.UserId.Value;

        foreach (var reply in comment.Replies)
        {
            foreach (var id in GetCommentTreeUserIds(reply))
                yield return id;
        }
    }

    private static VenueResponseDto MapVenue(Venue v) => new()
    {
        VenueId = v.VenueId,
        Name = v.Name,
        Address = v.Address,
        Latitude = v.Latitude,
        Longitude = v.Longitude,
        CityId = v.CityId,
        VenueType = v.VenueType,
        WebsiteUrl = v.WebsiteUrl,
        PhoneNumber = v.PhoneNumber,
        Description = v.Description,
        IsVerified = v.IsVerified,
        TimeZone = v.TimeZone,
        Locale = v.Locale,
        PriceZones = v.PriceZones.Select(MapPriceZone).ToList()
    };

    private static string ResolveDisplayName(CommentUserProfileDto? profile, int userId)
    {
        if (!string.IsNullOrWhiteSpace(profile?.Username))
            return profile.Username;

        if (!string.IsNullOrWhiteSpace(profile?.DisplayName))
            return profile.DisplayName;

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

    public async Task<ServiceResult<PagedResult<EventResponseDto>>> GetAllAsync(EventFilterDto filter)
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
}