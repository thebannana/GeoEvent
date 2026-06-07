using System.Security.Cryptography;
using MassTransit;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
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

    public UserServiceImpl(
        IUserRepository userRepository,
        PasswordService passwordService,
        IPublishEndpoint publishEndpoint,
        IExternalValidationService externalValidationService)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _publishEndpoint = publishEndpoint;
        _externalValidationService = externalValidationService;
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
            CityName = null,
            IsVerified = user.IsVerified,
            EventsCount = 0,
            FollowersCount = 0,
            FollowingCount = 0,
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
            return new List<CommentUserProfileDto>();

        var users = new List<UserService.Domain.Entities.User>();

        foreach (var id in distinctIds)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user is not null)
                users.Add(user);
        }

        return users.Select(u => new CommentUserProfileDto
        {
            UserId = u.PersonId,
            Username = u.Username,
            DisplayName = $"{u.Person?.FirstName} {u.Person?.LastName}".Trim(),
            AvatarUrl = string.IsNullOrWhiteSpace(u.Person?.ImageUrl) ? null : u.Person.ImageUrl
        }).ToList();
    }
    public async Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(
    int userId,
    UpdateProfileDto request)
    {
        var user = await _userRepository.GetByIdAsync(userId);
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

                user.IsVerified = false;
                user.EmailVerifiedAt = null;
                user.EmailVerificationToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
                user.EmailVerificationTokenExpiresAt = DateTime.UtcNow.AddHours(24);

                await _publishEndpoint.Publish(new EmailVerificationRequestedMessage(
                    user.PersonId,
                    user.Email,
                    user.EmailVerificationToken,
                    user.EmailVerificationTokenExpiresAt.Value));
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

        if (request.CityId is not null)
            person.CityId = request.CityId;

        person.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(user);
        return ServiceResult<UserProfileDto>.Ok(MapToProfile(user));
    }


    public async Task<ServiceResult<bool>> DeleteAccountAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null) return ServiceResult<bool>.NotFound($"User {userId} not found.");

        await _userRepository.SoftDeleteAsync(userId);
        await _publishEndpoint.Publish(new UserDeletedMessage(userId, DateTime.UtcNow));
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> BanUserAsync(int userId, string reason = "Policy violation")
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null) return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.IsBanned = true;
        await _userRepository.UpdateAsync(user);
        await _publishEndpoint.Publish(new UserBannedMessage(userId, user.Username, reason, DateTime.UtcNow));
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> UnbanUserAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null) return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.IsBanned = false;
        await _userRepository.UpdateAsync(user);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> VerifyEmailAsync(string token)
    {
        var user = await _userRepository.GetByVerificationTokenAsync(token);
        if (user is null || !user.IsEmailVerificationTokenValid(token))
            return ServiceResult<bool>.Unauthorized("Invalid or expired verification token.");

        user.VerifyEmail();
        await _userRepository.UpdateAsync(user);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ChangePasswordAsync(int userId, ChangePasswordDto dto)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null) return ServiceResult<bool>.NotFound($"User {userId} not found.");

        if (!_passwordService.VerifyPassword(dto.CurrentPassword, user.PasswordHash, user.PasswordSalt))
            return ServiceResult<bool>.Unauthorized("Current password is incorrect.");

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);
        user.PasswordHash = hash;
        user.PasswordSalt = salt;

        await _userRepository.RevokeAllUserTokensAsync(userId);
        await _userRepository.UpdateAsync(user);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<PagedResult<UserProfileDto>>> GetAllUsersAsync(UserFilterDto filter)
    {
        var result = await _userRepository.GetAllAsync(filter);
        var mapped = new PagedResult<UserProfileDto>
        {
            Items = result.Items.Select(MapToProfile),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };
        return ServiceResult<PagedResult<UserProfileDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> AdminVerifyUserAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null) return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.IsVerified = true;
        user.EmailVerifiedAt = DateTime.UtcNow;
        user.EmailVerificationToken = null;
        user.EmailVerificationTokenExpiresAt = null;
        await _userRepository.UpdateAsync(user);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<List<ActivityLogResponseDto>>> GetUserActivityLogsAsync(int userId, int page, int pageSize)
    {
        var logs = await _userRepository.GetUserActivityLogsAsync(userId, page, pageSize);
        return ServiceResult<List<ActivityLogResponseDto>>.Ok(logs.Select(MapActivityLog).ToList());
    }

    public async Task<ServiceResult<ActivityLogResponseDto>> LogActivityAsync(
        int userId,
        ActivityActionType actionType,
        ActivityTargetType targetType,
        int targetId,
        string metadata,
        Guid sessionId)
    {
        var log = new ActivityLog
        {
            UserId = userId,
            ActionType = actionType,
            TargetType = targetType,
            TargetId = targetId,
            Metadata = metadata,
            SessionId = sessionId,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _userRepository.CreateActivityLogAsync(log);
        return ServiceResult<ActivityLogResponseDto>.Ok(MapActivityLog(created));
    }

    public async Task<ServiceResult<List<UserPreferenceResponseDto>>> GetUserPreferencesAsync(int userId)
    {
        var prefs = await _userRepository.GetUserPreferencesAsync(userId);
        return ServiceResult<List<UserPreferenceResponseDto>>.Ok(prefs.Select(MapPreference).ToList());
    }

    public async Task<ServiceResult<UserPreferenceResponseDto>> UpsertPreferenceAsync(int userId, UpdatePreferenceDto dto)
    {
        var existing = await _userRepository.GetPreferenceAsync(userId, dto.SegmentId, dto.GenreId);

        if (existing is not null)
        {
            existing.UpdateScore(dto.Score);
            await _userRepository.UpdatePreferenceAsync(existing);
            return ServiceResult<UserPreferenceResponseDto>.Ok(MapPreference(existing));
        }

        var preference = new UserPreference
        {
            UserId = userId,
            SegmentId = dto.SegmentId,
            GenreId = dto.GenreId,
            Score = dto.Score,
            LastUpdated = DateTime.UtcNow
        };

        var created = await _userRepository.CreatePreferenceAsync(preference);
        return ServiceResult<UserPreferenceResponseDto>.Ok(MapPreference(created));
    }

    public async Task<ServiceResult<bool>> DeletePreferenceAsync(int userId, int prefId)
    {
        var prefs = await _userRepository.GetUserPreferencesAsync(userId);
        var pref = prefs.FirstOrDefault(p => p.PrefId == prefId);

        if (pref is null) return ServiceResult<bool>.NotFound("Preference not found.");
        if (pref.UserId != userId) return ServiceResult<bool>.Forbidden("Not your preference.");

        await _userRepository.DeletePreferenceAsync(pref);
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

        var report = new Report
        {
            TargetType = dto.TargetType,
            TargetId = dto.TargetId,
            Reason = dto.Reason.Trim(),
            Description = dto.Description?.Trim() ?? string.Empty,
            Status = ReportStatus.Pending,
            ReporterId = reporterId,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _userRepository.CreateReportAsync(report);
        return ServiceResult<ReportResponseDto>.Ok(MapReport(created));
    }

    public async Task<ServiceResult<List<ReportResponseDto>>> GetUserReportsAsync(int userId)
    {
        var reports = await _userRepository.GetUserReportsAsync(userId);
        return ServiceResult<List<ReportResponseDto>>.Ok(reports.Select(MapReport).ToList());
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
            Items = result.Items.Select(MapReport),
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
        var report = await _userRepository.GetReportByIdAsync(reportId);
        if (report is null)
            return ServiceResult<ReportResponseDto>.NotFound("Report not found.");

        if (report.Status == ReportStatus.Resolved || report.Status == ReportStatus.Dismissed)
            return ServiceResult<ReportResponseDto>.Conflict("Report has already been closed.");

        if (dto.Action == ReportResolutionAction.Resolve)
        {
            report.Resolve(resolvedById);
        }
        else if (dto.Action == ReportResolutionAction.Dismiss)
        {
            report.Dismiss(resolvedById);
        }
        else
        {
            return ServiceResult<ReportResponseDto>.Fail("Invalid action. Use Resolve or Dismiss.", 400);
        }

        await _userRepository.UpdateReportAsync(report);
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

    private static PublicUserProfileDto MapPublic(User user, double averageRating, int ratingsCount, int? myRating) => new()
    {
        UserId = user.PersonId,
        Username = user.Username,
        FirstName = user.Person?.FirstName ?? string.Empty,
        LastName = user.Person?.LastName ?? string.Empty,
        ImageUrl = string.IsNullOrWhiteSpace(user.Person?.ImageUrl) ? null : user.Person.ImageUrl,
        CityName = null,
        IsVerified = user.IsVerified,
        AverageRating = averageRating,
        RatingsCount = ratingsCount,
        MyRating = myRating
    };


    public async Task<ServiceResult<List<PublicUserProfileDto>>> GetPublicProfilesAsync(IEnumerable<int> userIds)
    {
        var users = await _userRepository.GetPublicByIdsAsync(userIds);

        var result = new List<PublicUserProfileDto>();

        foreach (var user in users)
        {
            var summary = await _userRepository.GetUserRatingSummaryAsync(user.PersonId);

            result.Add(new PublicUserProfileDto
            {
                UserId = user.PersonId,
                Username = user.Username,
                FirstName = user.Person?.FirstName ?? string.Empty,
                LastName = user.Person?.LastName ?? string.Empty,
                ImageUrl = string.IsNullOrWhiteSpace(user.Person?.ImageUrl) ? null : user.Person.ImageUrl,
                CityName = null,
                IsVerified = user.IsVerified,
                EventsCount = 0,
                FollowersCount = 0,
                FollowingCount = 0,
                AverageRating = summary.AverageRating,
                RatingsCount = summary.RatingsCount,
                MyRating = null,
                MyReviewComment = null
            });
        }

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

        var existing = await _userRepository.GetUserRatingAsync(raterId, ratedUserId);

        if (existing is null)
        {
            var rating = new UserRating
            {
                RaterId = raterId,
                RatedUserId = ratedUserId,
                Value = dto.Value,
                Comment = string.IsNullOrWhiteSpace(dto.Comment) ? null : dto.Comment.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            await _userRepository.CreateUserRatingAsync(rating);
        }
        else
        {
            existing.UpdateReview(dto.Value, dto.Comment);
            await _userRepository.UpdateUserRatingAsync(existing);
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteUserReviewAsync(int ratedUserId, int raterId)
    {
        if (ratedUserId == raterId)
            return ServiceResult<bool>.Fail("You cannot delete a review for yourself.", 400);

        var ratedUser = await _userRepository.GetByIdAsync(ratedUserId);
        if (ratedUser is null)
            return ServiceResult<bool>.NotFound("User not found.");

        var existing = await _userRepository.GetUserRatingAsync(raterId, ratedUserId);
        if (existing is null)
            return ServiceResult<bool>.NotFound("Review not found.");

        await _userRepository.DeleteUserRatingAsync(existing);
        return ServiceResult<bool>.Ok(true);
    }



    private static UserProfileDto MapToProfile(UserService.Domain.Entities.User user)
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
            IsVerified = user.IsVerified,
            CreatedAt = user.CreatedAt,
            CityId = person.CityId,
            CityName = null
        };
    }

    private static PublicUserProfileDto MapPublic(User user) => new()
    {
        UserId = user.PersonId,
        Username = user.Username,
        FirstName = user.Person?.FirstName ?? string.Empty,
        LastName = user.Person?.LastName ?? string.Empty,
        ImageUrl = string.IsNullOrWhiteSpace(user.Person?.ImageUrl) ? null : user.Person.ImageUrl,
        CityName = null,
        IsVerified = user.IsVerified,
        EventsCount = 0,
        FollowersCount = 0,
        FollowingCount = 0,
        AverageRating = 0,
        RatingsCount = 0,
        MyRating = null,
        MyReviewComment = null
    };

    private static ActivityLogResponseDto MapActivityLog(ActivityLog a) => new()
    {
        LogId = a.LogId,
        TargetId = a.TargetId,
        SessionId = a.SessionId,
        ActionType = a.ActionType.ToString(),
        TargetType = a.TargetType.ToString(),
        Metadata = a.Metadata,
        UserId = a.UserId,
        SegmentId = a.SegmentId,
        GenreId = a.GenreId,
        CreatedAt = a.CreatedAt
    };

    private static UserPreferenceResponseDto MapPreference(UserPreference p) => new()
    {
        PrefId = p.PrefId,
        UserId = p.UserId,
        SegmentId = p.SegmentId,
        GenreId = p.GenreId,
        Score = p.Score,
        LastUpdated = p.LastUpdated
    };
}