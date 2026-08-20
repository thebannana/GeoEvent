using EventService.Application.Common;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Repositories;
using EventService.Application.Interfaces.Services;
using EventService.Domain.Entities;
using EventService.Domain.Enums;
using EventService.Domain.Exceptions;
using EventService.Infrastructure.Repositories;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Events;
using DomainEvent = EventService.Domain.Entities.Event;

namespace EventService.Infrastructure.Services;

public class EventServiceImpl : IEventService
{
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 50;
    private const string SegmentsCacheKey = "eventservice:segments:all";

    private readonly IEventRepository _eventRepository;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IUserProfileService _userProfileService;
    private readonly IMemoryCache _cache;
    private readonly ILogger<EventServiceImpl> _logger;

    public EventServiceImpl(
        IEventRepository eventRepository,
        IPublishEndpoint publishEndpoint,
        IUserProfileService userProfileService,
        IMemoryCache cache,
        ILogger<EventServiceImpl> logger)
    {
        _eventRepository = eventRepository;
        _publishEndpoint = publishEndpoint;
        _userProfileService = userProfileService;
        _cache = cache;
        _logger = logger;
    }

    public async Task<ServiceResult<InternalEventLookupDto>> GetInternalEventLookupAsync(
        int eventId)
    {
        if (eventId <= 0)
        {
            return ServiceResult<InternalEventLookupDto>.Fail(
                "A valid event ID is required.",
                400);
        }

        var ev = await _eventRepository.GetByIdWithDetailsAsync(eventId);

        if (ev is null)
        {
            return ServiceResult<InternalEventLookupDto>.NotFound(
                "Event not found.");
        }

        string? organizerDisplayName = null;

        try
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(
                new[] { ev.OrganizerId });

            if (profiles.TryGetValue(ev.OrganizerId, out var organizer))
            {
                organizerDisplayName =
                    !string.IsNullOrWhiteSpace(organizer.DisplayName)
                        ? organizer.DisplayName
                        : organizer.Username;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Could not load organizer profile for event {EventId} and organizer {OrganizerId}",
                ev.EventId,
                ev.OrganizerId);
        }

        return ServiceResult<InternalEventLookupDto>.Ok(
            new InternalEventLookupDto
            {
                EventId = ev.EventId,
                Title = ev.Title,
                OrganizerDisplayName = organizerDisplayName
            });
    }

    public async Task<ServiceResult<InternalCommentLookupDto>> GetInternalCommentLookupAsync(
        int commentId)
    {
        if (commentId <= 0)
        {
            return ServiceResult<InternalCommentLookupDto>.Fail(
                "A valid comment ID is required.",
                400);
        }

        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
        {
            return ServiceResult<InternalCommentLookupDto>.NotFound(
                "Comment not found.");
        }

        string? username = null;
        string? userDisplayName = null;

        try
        {
            var profiles = await _userProfileService.GetProfilesByIdsAsync(
                new[] { comment.UserId });

            if (profiles.TryGetValue(comment.UserId, out var author))
            {
                username = author.Username;
                userDisplayName =
                    !string.IsNullOrWhiteSpace(author.DisplayName)
                        ? author.DisplayName
                        : author.Username;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Could not load author profile for comment {CommentId} and user {UserId}",
                comment.CommentId,
                comment.UserId);
        }

        return ServiceResult<InternalCommentLookupDto>.Ok(
            new InternalCommentLookupDto
            {
                CommentId = comment.CommentId,
                EventId = comment.EventId,
                UserId = comment.UserId,
                Username = username,
                UserDisplayName = userDisplayName,
                Preview = BuildLookupPreview(comment.Content, 120),
                IsDeleted = comment.IsDeleted
            });
    }

    private static string BuildLookupPreview(string? value, int maxLength = 120)
    {
        var text = string.IsNullOrWhiteSpace(value) ? string.Empty : value.Trim();
        if (string.IsNullOrEmpty(text))
            return string.Empty;

        return text.Length <= maxLength
            ? text
            : text[..maxLength].TrimEnd() + "...";
    }
    public async Task<ServiceResult<EventResponseDto>> GetAdminByIdAsync(int eventId)
    {
        var ev = await _eventRepository.GetByIdWithDetailsAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

        return ServiceResult<EventResponseDto>.Ok(MapToDto(ev));
    }

    public async Task<ServiceResult<EventResponseDto>> AdminUpdateAsync(int eventId, UpdateEventDto dto)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<EventResponseDto>.NotFound($"Event {eventId} not found.");

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
                isFeatured: dto.IsFeatured ?? ev.IsFeatured,
                tags: dto.Tags ?? ev.Tags,
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
                "Event updated by admin",
                DateTime.UtcNow
            ));

            var updated = await _eventRepository.GetByIdWithDetailsAsync(eventId) ?? ev;
            return ServiceResult<EventResponseDto>.Ok(MapToDto(updated));
        }
        catch (InvalidEventDataException ex)
        {
            _logger.LogWarning(ex, "Invalid event data while admin updated event {EventId}", eventId);
            return ServiceResult<EventResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> AdminDeleteImageAsync(
    int eventId,
    int imageId)
    {
        var image = await _eventRepository.GetImageAsync(imageId);

        if (image is null || image.EventId != eventId)
        {
            return ServiceResult<bool>.NotFound(
                "Image not found for this event.");
        }

        await _eventRepository.DeleteImageAsync(imageId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> AdminSetCoverImageAsync(
    int eventId,
    int imageId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);

        if (ev is null)
        {
            return ServiceResult<bool>.NotFound(
                $"Event {eventId} not found.");
        }

        var image = await _eventRepository.GetImageAsync(imageId);

        if (image is null || image.EventId != eventId)
        {
            return ServiceResult<bool>.NotFound(
                "Image not found for this event.");
        }

        await _eventRepository.SetCoverImageAsync(eventId, imageId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> AdminDeleteAsync(int eventId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);

        if (ev is null)
        {
            return ServiceResult<bool>.NotFound(
                $"Event {eventId} not found.");
        }

        try
        {
            var wasAlreadyCancelled = ev.Status == EventStatus.Cancelled;

            ev.Cancel();
            await _eventRepository.UpdateAsync(ev);

            if (!wasAlreadyCancelled)
            {
                await _publishEndpoint.Publish(new EventCancelledMessage(
                    ev.EventId,
                    ev.Title,
                    ev.OrganizerId,
                    DateTime.UtcNow,
                    "Cancelled by admin"
                ));
            }

            return ServiceResult<bool>.Ok(true);
        }
        catch (InvalidEventStateException ex)
        {
            _logger.LogWarning(
                ex,
                "Invalid state while admin cancelled event {EventId}",
                eventId);

            return ServiceResult<bool>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> AdminAddImageAsync(
    int eventId,
    string imageUrl,
    bool isCover)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);

        if (ev is null)
        {
            return ServiceResult<bool>.NotFound(
                $"Event {eventId} not found.");
        }

        try
        {
            await _eventRepository.AddImageAsync(
                new EventImage(eventId, imageUrl, isCover),
                isCover);

            return ServiceResult<bool>.Ok(true);
        }
        catch (InvalidEventImageException ex)
        {
            _logger.LogWarning(
                ex,
                "Invalid admin image operation for event {EventId}",
                eventId);

            return ServiceResult<bool>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<AdminEventStatsDto>> GetAdminEventStatsAsync()
    {
        const int topTake = 5;

        static List<TopEventStatDto> MapTopEvents(IEnumerable<TopEventStatRawDto> items) =>
            items.Select(x => new TopEventStatDto
            {
                EventId = x.EventId,
                Title = x.Title,
                ImageUrl = x.ImageUrl,
                Status = x.Status.ToString(),
                StartDateTime = x.StartDateTime,
                Count = x.Count
            }).ToList();

        var totalEventsCount = await _eventRepository.GetTotalEventsCountAsync();
        var confirmedEventsCount = await _eventRepository.GetEventsCountByStatusAsync(EventStatus.Confirmed);
        var pendingEventsCount = await _eventRepository.GetEventsCountByStatusAsync(EventStatus.Pending);
        var completedEventsCount = await _eventRepository.GetEventsCountByStatusAsync(EventStatus.Completed);
        var cancelledEventsCount = await _eventRepository.GetEventsCountByStatusAsync(EventStatus.Cancelled);

        var totalLikesCount = await _eventRepository.GetLikedEventsCountAsync();
        var totalBookmarksCount = await _eventRepository.GetBookmarksCountAsync();
        var totalCommentsCount = await _eventRepository.GetCommentsCountAsync();
        var totalViewsCount = await _eventRepository.GetTotalViewsCountAsync();

        var mostLikedEvents = await _eventRepository.GetMostLikedEventsAsync(topTake);
        var mostViewedEvents = await _eventRepository.GetMostViewedEventsAsync(topTake);
        var mostCommentedEvents = await _eventRepository.GetMostCommentedEventsAsync(topTake);
        var mostBookmarkedEvents = await _eventRepository.GetMostBookmarkedEventsAsync(topTake);

        var dto = new AdminEventStatsDto
        {
            TotalEventsCount = totalEventsCount,
            ConfirmedEventsCount = confirmedEventsCount,
            PendingEventsCount = pendingEventsCount,
            CompletedEventsCount = completedEventsCount,
            CancelledEventsCount = cancelledEventsCount,
            TotalLikesCount = totalLikesCount,
            TotalBookmarksCount = totalBookmarksCount,
            TotalCommentsCount = totalCommentsCount,
            TotalViewsCount = totalViewsCount,
            MostLikedEvents = MapTopEvents(mostLikedEvents),
            MostViewedEvents = MapTopEvents(mostViewedEvents),
            MostCommentedEvents = MapTopEvents(mostCommentedEvents),
            MostBookmarkedEvents = MapTopEvents(mostBookmarkedEvents)
        };

        return ServiceResult<AdminEventStatsDto>.Ok(dto);
    }
    public async Task<ServiceResult<InternalEventEngagementStatsDto>> GetInternalEngagementStatsAsync()
    {
        var bookmarksCount = await _eventRepository.GetBookmarksCountAsync();
        var commentsCount = await _eventRepository.GetCommentsCountAsync();
        var likedEventsCount = await _eventRepository.GetLikedEventsCountAsync();

        return ServiceResult<InternalEventEngagementStatsDto>.Ok(new InternalEventEngagementStatsDto
        {
            BookmarksCount = bookmarksCount,
            CommentsCount = commentsCount,
            LikedEventsCount = likedEventsCount
        });
    }

    public async Task<ServiceResult<PagedResultSegmentResponseDto>> GetSegmentsPagedAsync(
    int page,
    int pageSize,
    string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var result = await _eventRepository.GetSegmentsPagedAsync(page, pageSize, searchTerm);

        return ServiceResult<PagedResultSegmentResponseDto>.Ok(new PagedResultSegmentResponseDto
        {
            Items = result.Items.Select(MapSegment).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }

    public async Task<ServiceResult<PagedResultGenreResponseDto>> GetGenresPagedAsync(
        int page,
        int pageSize,
        string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var result = await _eventRepository.GetGenresPagedAsync(page, pageSize, searchTerm);

        return ServiceResult<PagedResultGenreResponseDto>.Ok(new PagedResultGenreResponseDto
        {
            Items = result.Items.Select(MapGenre).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }

    public async Task<ServiceResult<PagedResultSubGenreResponseDto>> GetSubGenresPagedAsync(
        int page,
        int pageSize,
        string? searchTerm)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var result = await _eventRepository.GetSubGenresPagedAsync(page, pageSize, searchTerm);

        return ServiceResult<PagedResultSubGenreResponseDto>.Ok(new PagedResultSubGenreResponseDto
        {
            Items = result.Items.Select(MapSubGenre).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }
    public async Task<ServiceResult<int>> GetPublicCountByOrganizerAsync(int userId)
    {
        if (userId <= 0)
            return ServiceResult<int>.Fail("A valid organizer id is required.");

        var count = await _eventRepository.CountPublicByOrganizerAsync(userId);
        return ServiceResult<int>.Ok(count);
    }
    public async Task<ServiceResult<CommentResponseDto>> GetCommentByIdAsync(int commentId, int? requesterId = null)
    {
        var comment = await _eventRepository.GetCommentTreeByIdAsync(commentId);
        if (comment is null || comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        var mapped = MapComment(comment, includeReplies: true);
        await EnrichCommentsAsync(new List<CommentResponseDto> { mapped }, requesterId);

        return ServiceResult<CommentResponseDto>.Ok(mapped);
    }

    public async Task<ServiceResult<CommentResponseDto>> CreateCommentAsync(CreateCommentDto dto, int userId)
    {
        Comment? parent = null;

        if (dto.ParentCommentId.HasValue)
        {
            parent = await _eventRepository.GetCommentByIdAsync(dto.ParentCommentId.Value);
            if (parent is null || parent.IsDeleted)
                return ServiceResult<CommentResponseDto>.NotFound($"Parent comment {dto.ParentCommentId.Value} not found.");
        }

        try
        {
            var comment = new Comment(userId, dto.EventId, dto.Content, dto.ParentCommentId);
            var created = await _eventRepository.CreateCommentAsync(comment);

            var reloaded = await _eventRepository.GetCommentTreeByIdAsync(created.CommentId) ?? created;
            var dtoResult = MapComment(reloaded, includeReplies: true);

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
            _logger.LogWarning(ex, "Invalid comment data for user {UserId} on event {EventId}", userId, dto.EventId);
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<CommentResponseDto>> UpdateCommentAsync(int commentId, UpdateCommentDto dto, int userId)
    {
        var comment = await _eventRepository.GetTrackedCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        if (comment.UserId != userId)
            return ServiceResult<CommentResponseDto>.Forbidden("Not your comment.");

        try
        {
            comment.Edit(dto.Content);
            await _eventRepository.UpdateCommentAsync(comment);

            var reloaded = await _eventRepository.GetCommentTreeByIdAsync(commentId) ?? comment;
            var dtoResult = MapComment(reloaded, includeReplies: true);
            await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

            return ServiceResult<CommentResponseDto>.Ok(dtoResult);
        }
        catch (InvalidCommentException ex)
        {
            _logger.LogWarning(ex, "Invalid comment data while updating comment {CommentId}", commentId);
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
        catch (CommentAlreadyDeletedException ex)
        {
            _logger.LogWarning(ex, "Attempted to edit deleted comment {CommentId}", commentId);
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<CommentResponseDto>> LikeCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        if (comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.Fail("Comment has been deleted.");

        if (await _eventRepository.IsCommentLikedByUserAsync(commentId, userId))
            return ServiceResult<CommentResponseDto>.Conflict("Comment already liked.");

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

        var updated = await _eventRepository.GetCommentTreeByIdAsync(commentId);
        if (updated is null || updated.IsDeleted)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        var dtoResult = MapComment(updated, includeReplies: true);
        await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

        return ServiceResult<CommentResponseDto>.Ok(dtoResult);
    }

    public async Task<ServiceResult<CommentResponseDto>> UnlikeCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        if (comment.IsDeleted)
            return ServiceResult<CommentResponseDto>.Fail("Comment has been deleted.");

        await _eventRepository.UnlikeCommentAsync(commentId, userId);

        var updated = await _eventRepository.GetCommentTreeByIdAsync(commentId);
        if (updated is null || updated.IsDeleted)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        var dtoResult = MapComment(updated, includeReplies: true);
        await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, userId);

        return ServiceResult<CommentResponseDto>.Ok(dtoResult);
    }

    public async Task<ServiceResult<PagedResult<CommentResponseDto>>> GetEventCommentsAsync(
    int eventId,
    int page,
    int pageSize,
    int? requesterId = null)
    {
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var pagedComments = await _eventRepository.GetEventCommentsAsync(eventId, page, pageSize);
        var mapped = pagedComments.Items.Select(c => MapComment(c, includeReplies: true)).ToList();

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
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

        var pagedReplies = await _eventRepository.GetRepliesAsync(commentId, page, pageSize);
        var mapped = pagedReplies.Items.Select(c => MapComment(c, includeReplies: true)).ToList();

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
        filter.Page = NormalizePage(filter.Page);
        filter.PageSize = NormalizePageSize(filter.PageSize);

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
    EventFilterDto filter, int? requesterId = null)
    {
        filter ??= new EventFilterDto();
        filter.Status = EventStatus.Confirmed;
        filter.Page = NormalizePage(filter.Page);
        filter.PageSize = NormalizePageSize(filter.PageSize);

        var usePreferences = requesterId.HasValue && filter.UsePreferences;

        if (!usePreferences)
        {
            var result = await _eventRepository.GetAllAsync(filter);
            return ServiceResult<PagedResult<EventResponseDto>>.Ok(
                new PagedResult<EventResponseDto>
                {
                    Items = result.Items.Select(e => MapToDto(e, false)).ToList(),
                    TotalCount = result.TotalCount,
                    Page = result.Page,
                    PageSize = result.PageSize
                });
        }

        var preferences = await _userProfileService.GetUserPreferencesAsync(requesterId!.Value);

        if (preferences.Count == 0)
        {
            var result = await _eventRepository.GetAllAsync(filter);
            var events = result.Items.ToList();
            var likedIds = await _eventRepository.GetLikedEventIdsAsync(
                requesterId.Value, events.Select(e => e.EventId));

            return ServiceResult<PagedResult<EventResponseDto>>.Ok(
                new PagedResult<EventResponseDto>
                {
                    Items = events.Select(e => MapToDto(e, likedIds.Contains(e.EventId))).ToList(),
                    TotalCount = result.TotalCount,
                    Page = result.Page,
                    PageSize = result.PageSize
                });
        }

        var candidates = await _eventRepository.GetPublicCandidatesAsync(filter);
        var ranked = candidates
            .Select(e => new { Event = e, Score = CalculatePreferenceScore(e, preferences) })
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Event.StartDateTime)
            .ThenByDescending(x => x.Event.LikesCount)
            .ThenBy(x => x.Event.EventId)
            .ToList();

        var totalCount = ranked.Count;
        var pagedEvents = ranked
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .Select(x => x.Event)
            .ToList();

        var likedEventIds = await _eventRepository.GetLikedEventIdsAsync(
            requesterId.Value, pagedEvents.Select(e => e.EventId));

        return ServiceResult<PagedResult<EventResponseDto>>.Ok(
            new PagedResult<EventResponseDto>
            {
                Items = pagedEvents.Select(e => MapToDto(e, likedEventIds.Contains(e.EventId))).ToList(),
                TotalCount = totalCount,
                Page = filter.Page,
                PageSize = filter.PageSize
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
        page = NormalizePage(page);
        pageSize = NormalizePageSize(pageSize);

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

    public async Task<ServiceResult<List<EventResponseDto>>> GetNearbyPublicAsync(
    NearbyEventSearchDto dto,
    int? requesterId = null)
    {
        if (dto is null)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Search parameters are required.");
        }

        if (!dto.Latitude.HasValue || !dto.Longitude.HasValue)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Latitude and Longitude are required.");
        }

        if (dto.Latitude.Value is < -90 or > 90)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Latitude must be between -90 and 90.");
        }

        if (dto.Longitude.Value is < -180 or > 180)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Longitude must be between -180 and 180.");
        }

        if (dto.RadiusKm <= 0 || dto.RadiusKm > 500)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Radius must be between 1 and 500 km.");
        }

        if (dto.Limit <= 0 || dto.Limit > 100)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Limit must be between 1 and 100.");
        }

        if (dto.MinPrice.HasValue && dto.MinPrice.Value < 0)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Minimum price cannot be negative.");
        }

        if (dto.MaxPrice.HasValue && dto.MaxPrice.Value < 0)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Maximum price cannot be negative.");
        }

        if (dto.MinPrice.HasValue &&
            dto.MaxPrice.HasValue &&
            dto.MinPrice.Value > dto.MaxPrice.Value)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Minimum price cannot be greater than maximum price.");
        }

        if (dto.SegmentId is <= 0 ||
            dto.GenreId is <= 0 ||
            dto.SubGenreId is <= 0)
        {
            return ServiceResult<List<EventResponseDto>>.Fail(
                "Category IDs must be greater than zero.");
        }

        var preferences = requesterId.HasValue && dto.UsePreferences
            ? await _userProfileService.GetUserPreferencesAsync(
                requesterId.Value)
            : Array.Empty<UserPreferenceDto>();

        var events = await _eventRepository.GetNearbyAsync(
            dto,
            preferences);

        var publicEvents = events
            .Where(e =>
                e.Status == EventStatus.Confirmed &&
                !e.IsPast())
            .Select(e => MapToDto(e, false))
            .ToList();

        if (requesterId.HasValue && publicEvents.Count > 0)
        {
            var likedEventIds =
                await _eventRepository.GetLikedEventIdsAsync(
                    requesterId.Value,
                    publicEvents.Select(e => e.EventId));

            publicEvents = events
                .Where(e =>
                    e.Status == EventStatus.Confirmed &&
                    !e.IsPast())
                .Select(e => MapToDto(
                    e,
                    likedEventIds.Contains(e.EventId)))
                .ToList();
        }

        return ServiceResult<List<EventResponseDto>>.Ok(publicEvents);
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
                isFeatured: false,
                tags: dto.Tags,
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
                created.StartDateTime,
                created.EndDateTime,
                DateTime.UtcNow
            ));

            return ServiceResult<EventResponseDto>.Created(MapToDto(created));
        }
        catch (InvalidEventDataException ex)
        {
            _logger.LogWarning(ex, "Invalid event data while creating event for organizer {OrganizerId}", organizerId);
            return ServiceResult<EventResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<EventResponseDto>> UpdateAsync(int eventId, UpdateEventDto dto, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
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
                isFeatured: dto.IsFeatured ?? ev.IsFeatured,
                tags: dto.Tags ?? ev.Tags,
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
            _logger.LogWarning(ex, "Invalid event data while updating event {EventId}", eventId);
            return ServiceResult<EventResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> DeleteAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You can only delete your own events.");

        try
        {
            ev.Cancel();
            await _eventRepository.UpdateAsync(ev);
            return ServiceResult<bool>.Ok(true);
        }
        catch (InvalidEventStateTransitionException ex)
        {
            _logger.LogWarning(ex, "Invalid state transition while deleting event {EventId}", eventId);
            return ServiceResult<bool>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> PublishAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
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

    public async Task<ServiceResult<bool>> CancelAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
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
            "Cancelled by organizer"));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> CompleteAsync(int eventId, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
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
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {eventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        try
        {
            await _eventRepository.AddImageAsync(
                new EventImage(eventId, imageUrl, isCover),
                isCover);

            return ServiceResult<bool>.Ok(true);
        }
        catch (InvalidEventImageException ex)
        {
            _logger.LogWarning(ex, "Invalid event image for event {EventId}", eventId);
            return ServiceResult<bool>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> DeleteImageAsync(int imageId, int requesterId)
    {
        var image = await _eventRepository.GetImageAsync(imageId);
        if (image is null)
            return ServiceResult<bool>.NotFound("Image not found.");

        var ev = await _eventRepository.GetTrackedByIdAsync(image.EventId);
        if (ev is null)
            return ServiceResult<bool>.NotFound($"Event {image.EventId} not found.");

        if (ev.OrganizerId != requesterId)
            return ServiceResult<bool>.Forbidden("You do not own this event.");

        await _eventRepository.DeleteImageAsync(imageId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> SetCoverImageAsync(int eventId, int imageId, int requesterId)
    {
        var ev = await _eventRepository.GetTrackedByIdAsync(eventId);
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
        var items = await _cache.GetOrCreateAsync(SegmentsCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var segments = await _eventRepository.GetAllSegmentsAsync();
            return segments.Select(MapSegment).ToList();
        });

        return ServiceResult<List<SegmentResponseDto>>.Ok(items!);
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
            var segment = new Segment(dto.Name, dto.Color);
            if (!dto.IsActive)
                segment.Deactivate();

            var created = await _eventRepository.CreateSegmentAsync(segment);
            InvalidateSegmentCache();

            return ServiceResult<SegmentResponseDto>.Created(MapSegment(created));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid segment data while creating segment");
            return ServiceResult<SegmentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<SegmentResponseDto>> UpdateSegmentAsync(int segmentId, UpdateSegmentDto dto)
    {
        var segment = await _eventRepository.GetTrackedSegmentByIdAsync(segmentId);
        if (segment is null)
            return ServiceResult<SegmentResponseDto>.NotFound("Segment not found.");

        try
        {
            segment.Update(
                dto.Name ?? segment.Name,
                dto.Color ?? segment.Color
            );

            if (dto.IsActive.HasValue)
            {
                if (dto.IsActive.Value) segment.Activate();
                else segment.Deactivate();
            }

            await _eventRepository.UpdateSegmentAsync(segment);
            InvalidateSegmentCache();

            return ServiceResult<SegmentResponseDto>.Ok(MapSegment(segment));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid segment data while updating segment {SegmentId}", segmentId);
            return ServiceResult<SegmentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<List<GenreResponseDto>>> GetGenresBySegmentAsync(int segmentId)
    {
        var cacheKey = $"eventservice:genres:segment:{segmentId}";

        var items = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var genres = await _eventRepository.GetGenresBySegmentAsync(segmentId);
            return genres.Select(MapGenre).ToList();
        });

        return ServiceResult<List<GenreResponseDto>>.Ok(items!);
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

            InvalidateGenresCache(dto.SegmentId);

            return ServiceResult<GenreResponseDto>.Created(MapGenre(createdWithDetails ?? created));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid genre data while creating genre for segment {SegmentId}", dto.SegmentId);
            return ServiceResult<GenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<GenreResponseDto>> UpdateGenreAsync(int genreId, UpdateGenreDto dto)
    {
        var genre = await _eventRepository.GetTrackedGenreByIdAsync(genreId);
        if (genre is null)
            return ServiceResult<GenreResponseDto>.NotFound("Genre not found.");

        var oldSegmentId = genre.SegmentId;
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

            InvalidateGenresCache(oldSegmentId);
            if (targetSegmentId != oldSegmentId)
                InvalidateGenresCache(targetSegmentId);

            var updated = await _eventRepository.GetGenreByIdAsync(genreId);

            return ServiceResult<GenreResponseDto>.Ok(MapGenre(updated ?? genre));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid genre data while updating genre {GenreId}", genreId);
            return ServiceResult<GenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<List<SubGenreResponseDto>>> GetSubGenresByGenreAsync(int genreId)
    {
        var cacheKey = $"eventservice:subgenres:genre:{genreId}";

        var items = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var subGenres = await _eventRepository.GetSubGenresByGenreAsync(genreId);
            return subGenres.Select(MapSubGenre).ToList();
        });

        return ServiceResult<List<SubGenreResponseDto>>.Ok(items!);
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
            InvalidateSubGenresCache(dto.GenreId);

            return ServiceResult<SubGenreResponseDto>.Created(MapSubGenre(created));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid subgenre data while creating subgenre for genre {GenreId}", dto.GenreId);
            return ServiceResult<SubGenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<SubGenreResponseDto>> UpdateSubGenreAsync(int subGenreId, UpdateSubGenreDto dto)
    {
        var subGenre = await _eventRepository.GetTrackedSubGenreByIdAsync(subGenreId);
        if (subGenre is null)
            return ServiceResult<SubGenreResponseDto>.NotFound("Subgenre not found.");

        var oldGenreId = subGenre.GenreId;
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

            InvalidateSubGenresCache(oldGenreId);
            if (targetGenreId != oldGenreId)
                InvalidateSubGenresCache(targetGenreId);

            return ServiceResult<SubGenreResponseDto>.Ok(MapSubGenre(subGenre));
        }
        catch (InvalidReferenceDataException ex)
        {
            _logger.LogWarning(ex, "Invalid subgenre data while updating subgenre {SubGenreId}", subGenreId);
            return ServiceResult<SubGenreResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<PagedResult<BookmarkResponseDto>>> GetUserBookmarksAsync(
        int userId,
        BookmarkFilterDto filter)
    {
        filter ??= new BookmarkFilterDto();

        var page = NormalizePage(filter.Page);
        var pageSize = NormalizePageSize(filter.PageSize);

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
            _logger.LogWarning(ex, "Invalid bookmark data for user {UserId} and event {EventId}", userId, dto.EventId);
            return ServiceResult<BookmarkResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<BookmarkResponseDto>> UpdateBookmarkAsync(int bookmarkId, UpdateBookmarkDto dto, int userId)
    {
        var bookmark = await _eventRepository.GetTrackedBookmarkByIdAsync(bookmarkId);
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
        var bookmark = await _eventRepository.GetTrackedBookmarkByIdAsync(bookmarkId);
        if (bookmark is null)
            return ServiceResult<bool>.NotFound("Bookmark not found.");

        if (bookmark.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your bookmark.");

        await _eventRepository.DeleteBookmarkAsync(bookmark);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteCommentAsync(int commentId, int userId)
    {
        var comment = await _eventRepository.GetTrackedCommentByIdAsync(commentId);

        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");

        if (comment.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your comment.");

        comment.Delete();
        await _eventRepository.UpdateCommentAsync(comment);

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

        HashSet<int> likedCommentIds = [];
        if (requesterId.HasValue)
        {
            likedCommentIds = await _eventRepository.GetLikedCommentIdsAsync(
                requesterId.Value,
                allComments.Select(c => c.CommentId));
        }

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

            comment.IsLiked = requesterId.HasValue && likedCommentIds.Contains(comment.CommentId);
        }
    }

    private static CommentResponseDto MapComment(Comment c, bool includeReplies = true)
    {
        var visibleReplies = includeReplies
            ? c.Replies.Where(r => !r.IsDeleted).Select(r => MapComment(r, true)).ToList()
            : new List<CommentResponseDto>();

        var replyCount = c.Replies?.Count(r => !r.IsDeleted) ?? 0;

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
            ReplyCount = replyCount,
            Replies = includeReplies ? visibleReplies : new List<CommentResponseDto>(),
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
        GenreName = s.Genre?.Name,
        SegmentId = s.Genre?.SegmentId,
        SegmentName = s.Genre?.Segment?.Name,
        IsActive = s.IsActive
    };

    private static BookmarkResponseDto MapBookmark(Bookmark b) => new()
    {
        BookmarkId = b.BookmarkId,
        Title = b.Event?.Title ?? "Saved event",
        ImageUrl = b.Event?.Images.FirstOrDefault(i => i.IsCover)?.ImageUrl
                   ?? b.Event?.Images.FirstOrDefault()?.ImageUrl
                   ?? string.Empty,
        SavedAt = b.SavedAt,
        Memo = b.Memo,
        EventId = b.EventId,
        UserId = b.UserId
    };

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

    public async Task<ServiceResult<CommentResponseDto>> AdminUpdateCommentAsync(int commentId, UpdateCommentDto dto)
    {
        var comment = await _eventRepository.GetTrackedCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<CommentResponseDto>.NotFound("Comment not found.");

        try
        {
            comment.Edit(dto.Content);

            await _eventRepository.UpdateCommentAsync(comment);

            var reloaded = await _eventRepository.GetCommentTreeByIdAsync(commentId) ?? comment;
            var dtoResult = MapComment(reloaded, includeReplies: true);

            await EnrichCommentsAsync(new List<CommentResponseDto> { dtoResult }, null);

            return ServiceResult<CommentResponseDto>.Ok(dtoResult);
        }
        catch (InvalidCommentException ex)
        {
            _logger.LogWarning(ex, "Invalid comment data while admin updated comment {CommentId}", commentId);
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
        catch (CommentAlreadyDeletedException ex)
        {
            _logger.LogWarning(ex, "Attempted to edit deleted comment {CommentId} as admin", commentId);
            return ServiceResult<CommentResponseDto>.Fail(ex.Message);
        }
    }

    public async Task<ServiceResult<bool>> AdminDeleteCommentAsync(int commentId)
    {
        var comment = await _eventRepository.GetTrackedCommentByIdAsync(commentId);
        if (comment is null)
            return ServiceResult<bool>.NotFound("Comment not found.");

        try
        {
            comment.Delete();

            await _eventRepository.UpdateCommentAsync(comment);

            return ServiceResult<bool>.Ok(true);
        }
        catch (CommentAlreadyDeletedException ex)
        {
            _logger.LogWarning(ex, "Attempted to delete already deleted comment {CommentId} as admin", commentId);
            return ServiceResult<bool>.Fail(ex.Message);
        }
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

    private static int NormalizePage(int page) => page <= 0 ? 1 : page;

    private static int NormalizePageSize(int pageSize) =>
        pageSize <= 0 ? DefaultPageSize : Math.Min(pageSize, MaxPageSize);

    private void InvalidateSegmentCache()
    {
        _cache.Remove(SegmentsCacheKey);
    }

    private void InvalidateGenresCache(int segmentId)
    {
        _cache.Remove($"eventservice:genres:segment:{segmentId}");
        _cache.Remove(SegmentsCacheKey);
    }

    private void InvalidateSubGenresCache(int genreId)
    {
        _cache.Remove($"eventservice:subgenres:genre:{genreId}");
    }
}