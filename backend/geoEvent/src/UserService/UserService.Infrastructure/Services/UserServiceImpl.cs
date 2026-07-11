using MassTransit;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;
using UserService.Domain.Enums;
using UserService.Domain.Exceptions;

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

    public async Task<ServiceResult<bool>> DeleteAccountAsync(int userId)
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

    public async Task<ServiceResult<PagedResult<ReportResponseDto>>> GetAllReportsAsync(
        ReportStatus? status,
        int page,
        int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 10 : Math.Min(pageSize, 100);

        var result = await _userRepository.GetReportsAsync(status, page, pageSize);

        var mapped = new PagedResult<ReportResponseDto>
        {
            Items = result.Items.Select(MapReport).ToList(),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };

        return ServiceResult<PagedResult<ReportResponseDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<ReportResponseDto>> GetReportByIdAsync(int reportId)
    {
        var report = await _userRepository.GetReportByIdAsync(reportId);
        if (report is null)
            return ServiceResult<ReportResponseDto>.NotFound("Report not found.");

        return ServiceResult<ReportResponseDto>.Ok(MapReport(report));
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
            CreatedAt = user.CreatedAt
        };
    }
}