using MassTransit;
using MassTransit.Transports;
using Microsoft.AspNetCore.Http;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;
using UserService.Domain.Enums;
using UserService.Domain.Exceptions;
using UserService.Infrastructure.Repositories;

namespace UserService.Infrastructure.Services;

public class UserServiceImpl : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly PasswordService _passwordService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IExternalValidationService _externalValidationService;
    private readonly IEventInternalClient _eventInternalClient;

    public UserServiceImpl(
        IUserRepository userRepository,
        PasswordService passwordService,
        IPublishEndpoint publishEndpoint,
        IExternalValidationService externalValidationService,
        IEventInternalClient eventInternalClient)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _publishEndpoint = publishEndpoint;
        _externalValidationService = externalValidationService;
        _eventInternalClient = eventInternalClient;
    }

    public async Task<ServiceResult<InternalReviewLookupDto>> GetInternalReviewLookupAsync(int reviewId)
    {
        if (reviewId <= 0)
            return ServiceResult<InternalReviewLookupDto>.Fail("A valid review ID must be provided.", 400);

        var review = await _userRepository.GetUserReviewByIdAsync(reviewId);
        if (review is null)
            return ServiceResult<InternalReviewLookupDto>.NotFound("Review not found.");

        var displayName = string.Join(" ",
            new[] { review.Rater?.Person?.FirstName, review.Rater?.Person?.LastName }
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x!.Trim()));

        return ServiceResult<InternalReviewLookupDto>.Ok(new InternalReviewLookupDto
        {
            ReviewId = review.RatingId,
            ReviewerId = review.RaterId,
            RatedUserId = review.RatedUserId,
            Value = review.Value,
            Username = review.Rater?.Username,
            UserDisplayName = string.IsNullOrWhiteSpace(displayName) ? review.Rater?.Username : displayName,
            Preview = BuildPreview(review.Comment, $"Rating {review.Value}/5", 120)
        });
    }
    public async Task<ServiceResult<PagedResult<AdminReportResponseDto>>> GetAllReportsAsync(AdminReportsQueryDto query)
    {
        query.Page = query.Page <= 0 ? 1 : query.Page;
        query.PageSize = query.PageSize <= 0 ? 10 : Math.Min(query.PageSize, 100);

        ReportStatus? parsedStatus = null;
        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            if (!Enum.TryParse<ReportStatus>(query.Status, true, out var status))
                return ServiceResult<PagedResult<AdminReportResponseDto>>.Fail("Invalid report status.", 400);

            parsedStatus = status;
        }

        ReportTargetType? parsedTargetType = null;
        if (!string.IsNullOrWhiteSpace(query.TargetType))
        {
            if (!Enum.TryParse<ReportTargetType>(query.TargetType, true, out var targetType))
                return ServiceResult<PagedResult<AdminReportResponseDto>>.Fail("Invalid report target type.", 400);

            parsedTargetType = targetType;
        }

        var normalizedSortBy = query.SortBy?.Trim() switch
        {
            null or "" => "createdAt",
            _ => query.SortBy!.Trim()
        };

        var result = await _userRepository.GetReportsAsync(
            parsedStatus,
            parsedTargetType,
            query.Search,
            normalizedSortBy,
            query.Descending,
            query.Page,
            query.PageSize);

        var mappedItems = await Task.WhenAll(result.Items.Select(MapAdminReportAsync));

        return ServiceResult<PagedResult<AdminReportResponseDto>>.Ok(new PagedResult<AdminReportResponseDto>
        {
            Items = mappedItems.ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        });
    }

    public async Task<ServiceResult<AdminReportResponseDto>> GetReportByIdAsync(int reportId)
    {
        var report = await _userRepository.GetReportByIdAsync(reportId);
        if (report is null)
            return ServiceResult<AdminReportResponseDto>.NotFound("Report not found.");

        return ServiceResult<AdminReportResponseDto>.Ok(await MapAdminReportAsync(report));
    }

    public async Task<ServiceResult<AdminReportResponseDto>> UpdateReportStatusAsync(
        int reportId,
        UpdateReportStatusDto dto,
        int adminUserId)
    {
        if (dto is null)
            return ServiceResult<AdminReportResponseDto>.Fail("Request body is required.", 400);

        if (string.IsNullOrWhiteSpace(dto.Status))
            return ServiceResult<AdminReportResponseDto>.Fail("Status is required.", 400);

        var report = await _userRepository.GetReportByIdForUpdateAsync(reportId);
        if (report is null)
            return ServiceResult<AdminReportResponseDto>.NotFound("Report not found.");

        if (!Enum.TryParse<ReportStatus>(dto.Status, true, out var nextStatus))
            return ServiceResult<AdminReportResponseDto>.Fail("Invalid report status.", 400);

        if (report.Status == ReportStatus.Resolved || report.Status == ReportStatus.Dismissed)
            return ServiceResult<AdminReportResponseDto>.Conflict("Report has already been closed.");

        switch (nextStatus)
        {
            case ReportStatus.Pending:
                return ServiceResult<AdminReportResponseDto>.Fail("Cannot move report back to pending.", 400);
            case ReportStatus.UnderReview:
                report.MarkUnderReview(adminUserId, dto.ResolutionNote, dto.ModeratorAction);
                break;
            case ReportStatus.Resolved:
                report.Resolve(adminUserId, dto.ResolutionNote, dto.ModeratorAction);
                break;
            case ReportStatus.Dismissed:
                report.Dismiss(adminUserId, dto.ResolutionNote, dto.ModeratorAction);
                break;
            default:
                return ServiceResult<AdminReportResponseDto>.Fail("Unsupported report status transition.", 400);
        }

        await _userRepository.UpdateReportAsync(report);
        await _userRepository.SaveChangesAsync();

        var reloaded = await _userRepository.GetReportByIdAsync(report.ReportId) ?? report;
        return ServiceResult<AdminReportResponseDto>.Ok(await MapAdminReportAsync(reloaded));
    }

    private async Task<(string TargetDisplay, string? TargetUsername, string Preview)> ResolveReportTargetAsync(Report r)
    {
        if (!r.TargetId.HasValue)
            return ("Unknown", null, BuildPreview(r.Description, r.Reason));

        var targetId = r.TargetId.Value;

        switch (r.TargetType)
        {
            case ReportTargetType.User:
                {
                    var user = await _userRepository.GetPublicByIdAsync(targetId);
                    if (user is null)
                        return ($"User #{targetId}", null, BuildPreview(r.Description, r.Reason));

                    var display = BuildPersonDisplayName(
                        user.Person?.FirstName,
                        user.Person?.LastName) ?? user.Username ?? $"User #{targetId}";

                    return (display, user.Username, BuildPreview(r.Description, r.Reason));
                }

            case ReportTargetType.Event:
                {
                    var lookup = await _externalValidationService.GetEventLookupAsync(targetId);
                    return lookup is null
                        ? ($"Event #{targetId}", null, BuildPreview(r.Description, r.Reason))
                        : (string.IsNullOrWhiteSpace(lookup.Title) ? $"Event #{targetId}" : lookup.Title.Trim(),
                           null,
                           BuildPreview(r.Description, r.Reason));
                }

            case ReportTargetType.Comment:
                {
                    var lookup = await _externalValidationService.GetCommentLookupAsync(targetId);
                    return lookup is null
                        ? ($"Comment #{targetId}", null, BuildPreview(r.Description, r.Reason))
                        : (string.IsNullOrWhiteSpace(lookup.UserDisplayName) ? $"Comment #{targetId}" : lookup.UserDisplayName!,
                           lookup.Username,
                           string.IsNullOrWhiteSpace(lookup.Preview) ? $"Comment #{targetId}" : lookup.Preview);
                }

            case ReportTargetType.Review:
                {
                    var lookup = await _externalValidationService.GetReviewLookupAsync(targetId);
                    return lookup is null
                        ? ($"Review #{targetId}", null, BuildPreview(r.Description, r.Reason))
                        : (string.IsNullOrWhiteSpace(lookup.UserDisplayName) ? $"Review #{targetId}" : lookup.UserDisplayName!,
                           lookup.Username,
                           string.IsNullOrWhiteSpace(lookup.Preview) ? $"Rating {lookup.Value}/5" : lookup.Preview);
                }

            default:
                return (r.TargetId.ToString()!, null, BuildPreview(r.Description, r.Reason));
        }
    }

    private async Task<AdminReportResponseDto> MapAdminReportAsync(Report r)
    {
        var reporterDisplayName = BuildPersonDisplayName(
            r.Reporter?.Person?.FirstName,
            r.Reporter?.Person?.LastName) ?? r.Reporter?.Username ?? $"User #{r.ReporterId}";

        var resolvedByDisplayName = BuildPersonDisplayName(
            r.ResolvedBy?.Person?.FirstName,
            r.ResolvedBy?.Person?.LastName) ?? r.ResolvedBy?.Username;

        var resolved = await ResolveReportTargetAsync(r);

        return new AdminReportResponseDto
        {
            ReportId = r.ReportId,
            TargetType = r.TargetType.ToString(),
            TargetId = r.TargetId,
            TargetDisplay = resolved.TargetDisplay,
            TargetUsername = resolved.TargetUsername,
            Reason = r.Reason,
            Description = r.Description,
            Preview = resolved.Preview,
            Status = r.Status.ToString(),
            ReporterId = r.ReporterId,
            ReporterUsername = r.Reporter?.Username ?? string.Empty,
            ReporterDisplayName = reporterDisplayName,
            ResolvedById = r.ResolvedById,
            ResolvedByUsername = r.ResolvedBy?.Username,
            ResolvedByDisplayName = resolvedByDisplayName,
            ResolutionNote = r.ResolutionNote,
            ModeratorAction = r.ModeratorAction,
            CreatedAt = r.CreatedAt,
            ResolvedAt = r.ResolvedAt
        };
    }

    private static string? BuildPersonDisplayName(string? firstName, string? lastName)
    {
        var value = string.Join(" ",
            new[] { firstName, lastName }
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x!.Trim()));

        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    public async Task<ServiceResult<ReportResponseDto>> CreateReportAsync(CreateReportDto dto, int reporterId)
    {
        if (dto is null)
            return ServiceResult<ReportResponseDto>.Fail("Report payload is required.", 400);

        if (dto.TargetId <= 0)
            return ServiceResult<ReportResponseDto>.Fail("TargetId is required.", 400);

        if (string.IsNullOrWhiteSpace(dto.Reason))
            return ServiceResult<ReportResponseDto>.Fail("Reason is required.", 400);

        var validation = await ValidateReportTargetAsync(dto);
        if (!validation.Success)
            return ServiceResult<ReportResponseDto>.Fail(validation.Error!, validation.StatusCode);

        if (dto.TargetType == ReportTargetType.User && dto.TargetId == reporterId)
            return ServiceResult<ReportResponseDto>.Fail("You cannot report yourself.", 400);

        var hasOpenReport = await _userRepository.HasOpenReportAsync(
            reporterId,
            dto.TargetType,
            dto.TargetId);

        if (hasOpenReport)
        {
            return ServiceResult<ReportResponseDto>.Conflict(
                "You already have an open report for this target.");
        }

        var report = new Report(
            dto.TargetType,
            dto.TargetId,
            dto.Reason,
            reporterId,
            dto.Description);

        var created = await _userRepository.CreateReportAsync(report);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<ReportResponseDto>.Ok(MapReport(created));
    }

    public async Task<ServiceResult<PagedResult<ReportResponseDto>>> GetUserReportsAsync(int userId, int page, int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 10 : Math.Min(pageSize, 50);

        var result = await _userRepository.GetUserReportsAsync(userId, page, pageSize);

        return ServiceResult<PagedResult<ReportResponseDto>>.Ok(
            new PagedResult<ReportResponseDto>
            {
                Items = result.Items.Select(MapReport).ToList(),
                TotalCount = result.TotalCount,
                Page = result.Page,
                PageSize = result.PageSize
            });
    }

    private async Task<ServiceResult<bool>> ValidateReportTargetAsync(CreateReportDto dto)
    {
        if (dto.TargetId <= 0)
            return ServiceResult<bool>.Fail("TargetId is required.", 400);

        return dto.TargetType switch
        {
            ReportTargetType.User =>
                await _userRepository.GetByIdAsync(dto.TargetId) is not null
                    ? ServiceResult<bool>.Ok(true)
                    : ServiceResult<bool>.NotFound("User not found."),

            ReportTargetType.Event =>
                await _externalValidationService.EventExistsAsync(dto.TargetId)
                    ? ServiceResult<bool>.Ok(true)
                    : ServiceResult<bool>.NotFound("Event not found."),

            ReportTargetType.Comment =>
                await _externalValidationService.CommentExistsAsync(dto.TargetId)
                    ? ServiceResult<bool>.Ok(true)
                    : ServiceResult<bool>.NotFound("Comment not found."),

            ReportTargetType.Review =>
                await _externalValidationService.ReviewExistsAsync(dto.TargetId)
                    ? ServiceResult<bool>.Ok(true)
                    : ServiceResult<bool>.NotFound("Review not found."),

            _ => ServiceResult<bool>.Fail("Unsupported report target type.", 400)
        };
    }

    private static ReportResponseDto MapReport(Report r) => new()
    {
        ReportId = r.ReportId,
        TargetType = r.TargetType.ToString(),
        TargetId = r.TargetId,
        Reason = r.Reason,
        Status = r.Status.ToString(),
        ReporterId = r.ReporterId,
        ResolvedById = r.ResolvedById,
        Description = r.Description,
        CreatedAt = r.CreatedAt,
        ResolvedAt = r.ResolvedAt
    };


    public async Task ApplyInteractionPreferenceAsync(
        int userId,
        int eventId,
        int? segmentId,
        int? genreId,
        int? subGenreId,
        string interactionType,
        DateTime occurredAt)
    {
        var (segmentWeight, genreWeight, subGenreWeight) = interactionType switch
        {
            "Like" => (1.0, 2.0, 3.0),
            "Bookmark" => (2.0, 3.0, 4.0),
            "Comment" => (2.0, 4.0, 5.0),
            "ReservationConfirmed" => (3.0, 5.0, 7.0),
            _ => (0.0, 0.0, 0.0)
        };

        var changed = false;

        if (segmentId.HasValue && segmentWeight > 0)
        {
            await UpsertIncrementPreferenceAsync(userId, segmentId, null, null, segmentWeight);
            changed = true;
        }

        if (segmentId.HasValue && genreId.HasValue && genreWeight > 0)
        {
            await UpsertIncrementPreferenceAsync(userId, segmentId, genreId, null, genreWeight);
            changed = true;
        }

        if (segmentId.HasValue && genreId.HasValue && subGenreId.HasValue && subGenreWeight > 0)
        {
            await UpsertIncrementPreferenceAsync(userId, segmentId, genreId, subGenreId, subGenreWeight);
            changed = true;
        }

        if (changed)
            await _userRepository.SaveChangesAsync();
    }

    private async Task UpsertIncrementPreferenceAsync(
        int userId,
        int? segmentId,
        int? genreId,
        int? subGenreId,
        double amount)
    {
        var existing = await _userRepository.GetPreferenceForUpdateAsync(userId, segmentId, genreId, subGenreId);

        if (existing is not null)
        {
            existing.IncrementScore(amount);
            await _userRepository.UpdatePreferenceAsync(existing);
            return;
        }

        var preference = new UserPreference
        {
            UserId = userId,
            SegmentId = segmentId,
            GenreId = genreId,
            SubGenreId = subGenreId,
            Score = amount,
            LastUpdated = DateTime.UtcNow
        };

        await _userRepository.CreatePreferenceAsync(preference);
    }

    public async Task<ServiceResult<UserProfileDto>> GetProfileAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<UserProfileDto>.NotFound($"User {userId} not found.");

        var profile = MapToProfile(user);
        var summary = await _userRepository.GetUserRatingSummaryAsync(userId);

        profile.AverageRating = summary.AverageRating;
        profile.RatingsCount = summary.RatingsCount;

        return ServiceResult<UserProfileDto>.Ok(profile);
    }

    public async Task<ServiceResult<PublicUserProfileDto>> GetPublicProfileAsync(int userId, int? requesterId = null)
    {
        var user = await _userRepository.GetPublicByIdAsync(userId);
        if (user is null)
            return ServiceResult<PublicUserProfileDto>.NotFound($"User {userId} not found.");

        var summary = await _userRepository.GetUserRatingSummaryAsync(userId);
        var eventsCount = await _eventInternalClient.GetOrganizerEventsCountAsync(userId);

        int? myRating = null;
        string? myReviewComment = null;

        if (requesterId.HasValue && requesterId.Value != userId)
        {
            var myReview = await _userRepository.GetUserRatingAsync(requesterId.Value, userId);
            myRating = myReview?.Value;
            myReviewComment = myReview?.Comment;
        }

        return ServiceResult<PublicUserProfileDto>.Ok(new PublicUserProfileDto
        {
            UserId = user.PersonId,
            Username = user.Username,
            FirstName = user.Person?.FirstName ?? string.Empty,
            LastName = user.Person?.LastName ?? string.Empty,
            ImageUrl = string.IsNullOrWhiteSpace(user.Person?.ImageUrl) ? null : user.Person.ImageUrl,
            EventsCount = eventsCount,
            AverageRating = summary.AverageRating,
            RatingsCount = summary.RatingsCount,
            MyRating = myRating,
            MyReviewComment = myReviewComment
        });
    }

    public async Task<List<CommentUserProfileDto>> GetCommentUserProfilesAsync(IEnumerable<int> ids)
    {
        var distinctIds = ids
            .Where(x => x > 0)
            .Distinct()
            .ToList();

        if (distinctIds.Count == 0)
            return [];

        var users = await _userRepository.GetPublicByIdsAsync(distinctIds);

        return users.Select(u => new CommentUserProfileDto
        {
            UserId = u.PersonId,
            Username = u.Username,
            DisplayName = $"{u.Person?.FirstName} {u.Person?.LastName}".Trim(),
            AvatarUrl = string.IsNullOrWhiteSpace(u.Person?.ImageUrl) ? null : u.Person.ImageUrl
        }).ToList();
    }

    public async Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileDto request)
    {
        var user = await _userRepository.GetByIdForUpdateAsync(userId);
        if (user is null)
            return ServiceResult<UserProfileDto>.NotFound($"User {userId} not found.");

        var person = user.Person;
        if (person is null)
            return ServiceResult<UserProfileDto>.Fail("User profile data is missing.", 500);

        if (!string.IsNullOrWhiteSpace(request.Username))
        {
            var normalizedUsername = request.Username.Trim().ToLowerInvariant();

            if (!string.Equals(user.Username, normalizedUsername, StringComparison.OrdinalIgnoreCase))
            {
                if (await _userRepository.UsernameExistsAsync(normalizedUsername))
                    throw new UsernameTakenException(normalizedUsername);

                user.Username = normalizedUsername;
            }
        }

        if (!string.IsNullOrWhiteSpace(request.Email))
        {
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();

            if (!string.Equals(user.Email, normalizedEmail, StringComparison.OrdinalIgnoreCase))
            {
                if (await _userRepository.EmailExistsAsync(normalizedEmail))
                    throw new EmailAlreadyTakenException(normalizedEmail);

                user.Email = normalizedEmail;
            }
        }

        if (request.FirstName is not null)
            person.FirstName = request.FirstName.Trim();

        if (request.LastName is not null)
            person.LastName = request.LastName.Trim();

        if (request.PhoneNumber is not null)
            person.PhoneNumber = request.PhoneNumber.Trim();

        if (request.ImageUrl is not null)
            person.ImageUrl = request.ImageUrl.Trim();

        person.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<UserProfileDto>.Ok(MapToProfile(user));
    }
    public async Task<ServiceResult<bool>> AdminDeleteUserAsync(int userId)
    {
        return await DeleteUserInternalAsync(userId);
    }

    public async Task<ServiceResult<bool>> DeleteAccountAsync(int userId)
    {
        return await DeleteUserInternalAsync(userId);
    }

    private async Task<ServiceResult<bool>> DeleteUserInternalAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        await _userRepository.SoftDeleteAsync(userId);
        await _userRepository.SaveChangesAsync();

        await _publishEndpoint.Publish(new UserDeletedMessage(userId, DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }
    public async Task<ServiceResult<bool>> BanUserAsync(int userId, string reason = "Policy violation")
    {
        var user = await _userRepository.GetByIdForUpdateAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.Ban();
        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        await _publishEndpoint.Publish(new UserBannedMessage(userId, user.Username, reason, DateTime.UtcNow));
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> UnbanUserAsync(int userId)
    {
        var user = await _userRepository.GetByIdForUpdateAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.Unban();
        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ChangePasswordAsync(int userId, ChangePasswordDto dto)
    {
        var user = await _userRepository.GetByIdForUpdateAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        if (!_passwordService.VerifyPassword(dto.CurrentPassword, user.PasswordHash, user.PasswordSalt))
            return ServiceResult<bool>.Unauthorized("Current password is incorrect.");

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);
        user.ChangePassword(hash, salt);

        await _userRepository.RevokeAllUserTokensAsync(userId);
        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<PagedResult<UserProfileDto>>> GetAllUsersAsync(UserFilterDto filter)
    {
        var result = await _userRepository.GetAllAsync(filter);
        var mapped = new PagedResult<UserProfileDto>
        {
            Items = result.Items.Select(MapToProfile).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };

        return ServiceResult<PagedResult<UserProfileDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<PagedResult<UserPreferenceResponseDto>>> GetUserPreferencesAsync(
        int userId,
        PreferencesFilterDto filter)
    {
        filter ??= new PreferencesFilterDto();

        var page = filter.Page < 1 ? 1 : filter.Page;
        var pageSize = filter.PageSize < 1 ? 20 : Math.Min(filter.PageSize, 100);

        var pagedPrefs = await _userRepository.GetUserPreferencesAsync(userId);
        var filtered = pagedPrefs.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(filter.Type))
        {
            var type = filter.Type.Trim().ToLowerInvariant();

            filtered = type switch
            {
                "segment" => filtered.Where(p =>
                    p.SegmentId != null &&
                    p.GenreId == null &&
                    p.SubGenreId == null),

                "genre" => filtered.Where(p =>
                    p.GenreId != null &&
                    p.SubGenreId == null),

                "subgenre" => filtered.Where(p =>
                    p.SubGenreId != null),

                _ => filtered
            };
        }

        if (filter.MinScore.HasValue)
            filtered = filtered.Where(p => p.Score >= filter.MinScore.Value);

        if (filter.MaxScore.HasValue)
            filtered = filtered.Where(p => p.Score <= filter.MaxScore.Value);

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLowerInvariant();

            filtered = filtered.Where(p =>
                (p.SegmentId?.ToString().Contains(search) ?? false) ||
                (p.GenreId?.ToString().Contains(search) ?? false) ||
                (p.SubGenreId?.ToString().Contains(search) ?? false));
        }

        var ordered = filtered
            .OrderByDescending(p => p.Score)
            .ThenBy(p => p.SegmentId ?? 0)
            .ThenBy(p => p.GenreId ?? 0)
            .ThenBy(p => p.SubGenreId ?? 0)
            .ToList();

        var totalCount = ordered.Count;

        var items = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(MapPreference)
            .ToList();

        var result = new PagedResult<UserPreferenceResponseDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };

        return ServiceResult<PagedResult<UserPreferenceResponseDto>>.Ok(result);
    }

    private static UserPreferenceResponseDto MapPreference(UserPreference preference) => new()
    {
        PrefId = preference.PrefId,
        UserId = preference.UserId,
        SegmentId = preference.SegmentId,
        GenreId = preference.GenreId,
        SubGenreId = preference.SubGenreId,
        Score = preference.Score,
        LastUpdated = preference.LastUpdated
    };

    public async Task<ServiceResult<UserPreferenceResponseDto>> UpsertPreferenceAsync(int userId, UpdatePreferenceDto dto)
    {
        var existing = await _userRepository.GetPreferenceForUpdateAsync(
            userId,
            dto.SegmentId,
            dto.GenreId,
            dto.SubGenreId);

        if (existing is not null)
        {
            existing.UpdateScore(dto.Score);
            await _userRepository.UpdatePreferenceAsync(existing);
            await _userRepository.SaveChangesAsync();

            return ServiceResult<UserPreferenceResponseDto>.Ok(MapPreference(existing));
        }

        var preference = new UserPreference
        {
            UserId = userId,
            SegmentId = dto.SegmentId,
            GenreId = dto.GenreId,
            SubGenreId = dto.SubGenreId,
            Score = dto.Score,
            LastUpdated = DateTime.UtcNow
        };

        var created = await _userRepository.CreatePreferenceAsync(preference);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<UserPreferenceResponseDto>.Ok(MapPreference(created));
    }

    public async Task<ServiceResult<bool>> DeletePreferenceAsync(int userId, int prefId)
    {
        var prefs = await _userRepository.GetUserPreferencesAsync(userId);
        var pref = prefs.FirstOrDefault(p => p.PrefId == prefId);

        if (pref is null)
            return ServiceResult<bool>.NotFound("Preference not found.");

        await _userRepository.DeletePreferenceAsync(pref);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }


    public async Task<ServiceResult<ReportResponseDto>> ResolveReportAsync(
        int reportId,
        ResolveReportDto dto,
        int resolvedById)
    {
        var report = await _userRepository.GetReportByIdForUpdateAsync(reportId);
        if (report is null)
            return ServiceResult<ReportResponseDto>.NotFound("Report not found.");

        if (report.Status == ReportStatus.Resolved || report.Status == ReportStatus.Dismissed)
            return ServiceResult<ReportResponseDto>.Conflict("Report has already been closed.");

        if (dto.Action == ReportResolutionAction.Resolve)
        {
            report.Resolve(resolvedById, dto.ResolutionNote, dto.ModeratorAction);
        }
        else if (dto.Action == ReportResolutionAction.Dismiss)
        {
            report.Dismiss(resolvedById, dto.ResolutionNote, dto.ModeratorAction);
        }
        else
        {
            return ServiceResult<ReportResponseDto>.Fail("Invalid action. Use Resolve or Dismiss.", 400);
        }

        await _userRepository.UpdateReportAsync(report);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<ReportResponseDto>.Ok(MapReport(report));
    }

    public async Task<ServiceResult<PagedResult<UserReviewResponseDto>>> GetUserReviewsAsync(int userId, int page, int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 10 : Math.Min(pageSize, 50);

        var user = await _userRepository.GetPublicByIdAsync(userId);
        if (user is null)
            return ServiceResult<PagedResult<UserReviewResponseDto>>.NotFound("User not found.");

        var items = await _userRepository.GetUserReviewsAsync(userId, page, pageSize);
        var total = await _userRepository.GetUserReviewsCountAsync(userId);

        return ServiceResult<PagedResult<UserReviewResponseDto>>.Ok(
            new PagedResult<UserReviewResponseDto>
            {
                Items = items.Select(x => new UserReviewResponseDto
                {
                    RatingId = x.RatingId,
                    ReviewerId = x.RaterId,
                    ReviewerUsername = x.Rater?.Username ?? string.Empty,
                    ReviewerDisplayName = $"{x.Rater?.Person?.FirstName} {x.Rater?.Person?.LastName}".Trim(),
                    ReviewerImageUrl = string.IsNullOrWhiteSpace(x.Rater?.Person?.ImageUrl)
                        ? null
                        : x.Rater!.Person!.ImageUrl,
                    RatedUserId = x.RatedUserId,
                    Value = x.Value,
                    Comment = x.Comment,
                    CreatedAt = x.CreatedAt,
                    UpdatedAt = x.UpdatedAt
                }).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            });
    }

    public async Task<ServiceResult<List<PublicUserProfileDto>>> GetPublicProfilesAsync(IEnumerable<int> userIds)
    {
        var users = await _userRepository.GetPublicByIdsAsync(userIds);
        var userIdList = users.Select(u => u.PersonId).ToList();
        var summaries = await _userRepository.GetUserRatingSummariesAsync(userIdList);

        var result = users.Select(user =>
        {
            var summary = summaries.TryGetValue(user.PersonId, out var value)
                ? value
                : (0d, 0);

            return new PublicUserProfileDto
            {
                UserId = user.PersonId,
                Username = user.Username,
                FirstName = user.Person?.FirstName ?? string.Empty,
                LastName = user.Person?.LastName ?? string.Empty,
                ImageUrl = string.IsNullOrWhiteSpace(user.Person?.ImageUrl) ? null : user.Person.ImageUrl,
                EventsCount = 0,
                AverageRating = summary.Item1,
                RatingsCount = summary.Item2,
                MyRating = null,
                MyReviewComment = null
            };
        }).ToList();

        return ServiceResult<List<PublicUserProfileDto>>.Ok(result);
    }

    public async Task<ServiceResult<AdminUserProfileDetailsDto>> GetAdminProfileAsync(
    int userId,
    int? requesterId = null)
    {
        if (userId <= 0)
            return ServiceResult<AdminUserProfileDetailsDto>.Fail("A valid user ID must be provided.");

        var user = await _userRepository.GetPublicByIdAsync(userId);
        if (user is null)
            return ServiceResult<AdminUserProfileDetailsDto>.NotFound($"User {userId} not found.");

        var summary = await _userRepository.GetUserRatingSummaryAsync(userId);
        var eventsCount = await _eventInternalClient.GetOrganizerEventsCountAsync(userId);

        var person = user.Person!;

        var dto = new AdminUserProfileDetailsDto
        {
            UserId = user.PersonId,
            Username = user.Username,
            Email = user.Email,
            FirstName = person.FirstName ?? string.Empty,
            LastName = person.LastName ?? string.Empty,
            PhoneNumber = string.IsNullOrWhiteSpace(person.PhoneNumber) ? null : person.PhoneNumber,
            ImageUrl = string.IsNullOrWhiteSpace(person.ImageUrl) ? null : person.ImageUrl,
            Role = user.Role.ToString(),
            IsBanned = user.IsBanned,
            CreatedAt = user.CreatedAt,
            EventsCount = eventsCount,
            AverageRating = summary.AverageRating,
            RatingsCount = summary.RatingsCount,
        };

        return ServiceResult<AdminUserProfileDetailsDto>.Ok(dto);
    }

    public async Task<ServiceResult<bool>> RateUserAsync(int ratedUserId, int raterId, RateUserDto dto)
    {
        if (dto is null)
            return ServiceResult<bool>.Fail("Rating payload is required.", 400);

        if (dto.Value < 1 || dto.Value > 5)
            return ServiceResult<bool>.Fail("Rating must be between 1 and 5.", 400);

        if (dto.Comment?.Trim().Length > 1000)
            return ServiceResult<bool>.Fail("Review comment cannot exceed 1000 characters.", 400);

        if (ratedUserId == raterId)
            return ServiceResult<bool>.Fail("You cannot rate yourself.", 400);

        var ratedUser = await _userRepository.GetByIdAsync(ratedUserId);
        if (ratedUser is null)
            return ServiceResult<bool>.NotFound("User not found.");

        var existing = await _userRepository.GetUserRatingForUpdateAsync(raterId, ratedUserId);

        if (existing is null)
        {
            var rating = new UserRating(raterId, ratedUserId, dto.Value, dto.Comment);
            await _userRepository.CreateUserRatingAsync(rating);
        }
        else
        {
            existing.UpdateReview(dto.Value, dto.Comment);
            await _userRepository.UpdateUserRatingAsync(existing);
        }

        await _userRepository.SaveChangesAsync();
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteUserReviewAsync(int ratedUserId, int raterId)
    {
        if (ratedUserId == raterId)
            return ServiceResult<bool>.Fail("You cannot delete a review for yourself.", 400);

        var ratedUser = await _userRepository.GetByIdAsync(ratedUserId);
        if (ratedUser is null)
            return ServiceResult<bool>.NotFound("User not found.");

        var existing = await _userRepository.GetUserRatingForUpdateAsync(raterId, ratedUserId);
        if (existing is null)
            return ServiceResult<bool>.NotFound("Review not found.");

        await _userRepository.DeleteUserRatingAsync(existing);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<UserProfileDto>> AdminUpdateUserAsync(int userId, AdminUpdateUserDto request)
    {
        if (request is null)
            return ServiceResult<UserProfileDto>.Fail("Request body is required.", 400);

        var user = await _userRepository.GetByIdForUpdateAsync(userId);
        if (user is null)
            return ServiceResult<UserProfileDto>.NotFound($"User {userId} not found.");

        var person = user.Person;
        if (person is null)
            return ServiceResult<UserProfileDto>.Fail("User profile data is missing.", 500);

        if (string.IsNullOrWhiteSpace(request.Username))
            return ServiceResult<UserProfileDto>.Fail("Username is required.", 400);

        if (string.IsNullOrWhiteSpace(request.Email))
            return ServiceResult<UserProfileDto>.Fail("Email is required.", 400);

        if (string.IsNullOrWhiteSpace(request.FirstName))
            return ServiceResult<UserProfileDto>.Fail("First name is required.", 400);

        if (string.IsNullOrWhiteSpace(request.LastName))
            return ServiceResult<UserProfileDto>.Fail("Last name is required.", 400);

        if (string.IsNullOrWhiteSpace(request.Role))
            return ServiceResult<UserProfileDto>.Fail("Role is required.", 400);

        var normalizedUsername = request.Username.Trim().ToLowerInvariant();
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();

        if (!string.Equals(user.Username, normalizedUsername, StringComparison.OrdinalIgnoreCase) &&
            await _userRepository.UsernameExistsAsync(normalizedUsername))
        {
            throw new UsernameTakenException(normalizedUsername);
        }

        if (!string.Equals(user.Email, normalizedEmail, StringComparison.OrdinalIgnoreCase) &&
            await _userRepository.EmailExistsAsync(normalizedEmail))
        {
            throw new EmailAlreadyTakenException(normalizedEmail);
        }

        if (!Enum.TryParse<UserRole>(request.Role, true, out var parsedRole))
            return ServiceResult<UserProfileDto>.Fail("Invalid role value.", 400);

        user.Username = normalizedUsername;
        user.Email = normalizedEmail;
        user.SetRole(parsedRole);

        person.FirstName = request.FirstName.Trim();
        person.LastName = request.LastName.Trim();
        person.PhoneNumber = request.PhoneNumber?.Trim() ?? string.Empty;
        person.ImageUrl = request.ImageUrl?.Trim() ?? string.Empty;
        person.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<UserProfileDto>.Ok(MapToProfile(user));
    }

    private static UserProfileDto MapToProfile(User user)
    {
        var person = user.Person!;

        return new UserProfileDto
        {
            UserId = user.PersonId,
            Username = user.Username,
            Email = user.Email,
            FirstName = person.FirstName,
            LastName = person.LastName,
            PhoneNumber = person.PhoneNumber,
            ImageUrl = person.ImageUrl,
            Role = user.Role.ToString(),
            IsBanned = user.IsBanned,
            CreatedAt = user.CreatedAt
        };
    }

    private static List<DashboardPreferenceStatDto> MapSegmentStats(
    IEnumerable<DashboardPreferenceAggregateRawDto> raw,
    IReadOnlyDictionary<int, EventSegmentLookupDto> segments)
    {
        return raw.Select(item =>
        {
            segments.TryGetValue(item.Id, out var segment);

            return new DashboardPreferenceStatDto
            {
                Id = item.Id,
                Name = segment?.Name ?? $"Segment #{item.Id}",
                ParentName = null,
                Color = segment?.Color,
                TotalScore = item.TotalScore,
                UserCount = item.UserCount
            };
        }).ToList();
    }

    private static List<DashboardPreferenceStatDto> MapGenreStats(
        IEnumerable<DashboardPreferenceAggregateRawDto> raw,
        IReadOnlyDictionary<int, EventGenreLookupDto> genres)
    {
        return raw.Select(item =>
        {
            genres.TryGetValue(item.Id, out var genre);

            return new DashboardPreferenceStatDto
            {
                Id = item.Id,
                Name = genre?.Name ?? $"Genre #{item.Id}",
                ParentName = genre?.SegmentName,
                Color = null,
                TotalScore = item.TotalScore,
                UserCount = item.UserCount
            };
        }).ToList();
    }

    private static List<DashboardPreferenceStatDto> MapSubGenreStats(
        IEnumerable<DashboardPreferenceAggregateRawDto> raw,
        IReadOnlyDictionary<int, EventSubGenreLookupDto> subGenres)
    {
        return raw.Select(item =>
        {
            subGenres.TryGetValue(item.Id, out var subGenre);

            return new DashboardPreferenceStatDto
            {
                Id = item.Id,
                Name = subGenre?.Name ?? $"SubGenre #{item.Id}",
                ParentName = subGenre?.GenreName,
                Color = null,
                TotalScore = item.TotalScore,
                UserCount = item.UserCount
            };
        }).ToList();
    }

    private static string BuildPreview(string? description, string reason, int maxLength = 120)
    {
        var source = string.IsNullOrWhiteSpace(description) ? reason : description.Trim();

        if (source.Length <= maxLength)
            return source;

        return source[..maxLength].TrimEnd() + "...";
    }
    public async Task<ServiceResult<AdminUsersDashboardStatsDto>> GetAdminUsersDashboardStatsAsync()
    {
        try
        {
            const int topTake = 5;
            var activeSinceUtc = DateTime.UtcNow.AddDays(-30);

            var activeUsersCount = await _userRepository.GetActiveUsersCountAsync(activeSinceUtc);
            var totalReportsCount = await _userRepository.GetReportsCountAsync();
            var topSegments = await _userRepository.GetTopSegmentsRawAsync(topTake);
            var topGenres = await _userRepository.GetTopGenresRawAsync(topTake);
            var topSubGenres = await _userRepository.GetTopSubGenresRawAsync(topTake);

            var segments = (await _eventInternalClient.GetAllSegmentsAsync()) ?? [];

            InternalEventEngagementStatsDto? engagement = null;
            try
            {
                engagement = await _eventInternalClient.GetEngagementStatsAsync();
            }
            catch
            {
                engagement = null;
            }

            var segmentMap = segments
                .Where(x => x != null)
                .GroupBy(x => x.SegmentId)
                .Select(g => g.First())
                .ToDictionary(x => x.SegmentId);

            var genreMap = segments
                .Where(x => x?.Genres != null)
                .SelectMany(x => x.Genres!)
                .Where(x => x != null)
                .GroupBy(x => x.GenreId)
                .Select(g => g.First())
                .ToDictionary(x => x.GenreId);

            var subGenreMap = segments
                .Where(x => x?.Genres != null)
                .SelectMany(x => x.Genres!)
                .Where(x => x?.SubGenres != null)
                .SelectMany(x => x.SubGenres!)
                .Where(x => x != null)
                .GroupBy(x => x.SubGenreId)
                .Select(g => g.First())
                .ToDictionary(x => x.SubGenreId);

            var dto = new AdminUsersDashboardStatsDto
            {
                ActiveUsersCount = activeUsersCount,
                TotalReportsCount = totalReportsCount,
                BookmarksCount = engagement?.BookmarksCount ?? 0,
                CommentsCount = engagement?.CommentsCount ?? 0,
                LikedEventsCount = engagement?.LikedEventsCount ?? 0,
                TopSegments = MapSegmentStats(topSegments, segmentMap),
                TopGenres = MapGenreStats(topGenres, genreMap),
                TopSubGenres = MapSubGenreStats(topSubGenres, subGenreMap)
            };

            return ServiceResult<AdminUsersDashboardStatsDto>.Ok(dto);
        }
        catch (Exception ex)
        {
            return ServiceResult<AdminUsersDashboardStatsDto>.Fail(
                $"Failed to load admin users dashboard stats: {ex.Message}",
                StatusCodes.Status500InternalServerError);
        }
    }
}