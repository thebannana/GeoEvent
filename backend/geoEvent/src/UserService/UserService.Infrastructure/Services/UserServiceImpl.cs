using MassTransit;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;
using UserService.Domain.Enums;

namespace UserService.Infrastructure.Services;

public class UserServiceImpl : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly PasswordService _passwordService;
    private readonly IPublishEndpoint _publishEndpoint;

    public UserServiceImpl(IUserRepository userRepository, PasswordService passwordService, IPublishEndpoint publishEndpoint)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _publishEndpoint = publishEndpoint;
    }


    public async Task<ServiceResult<bool>> ChangePasswordAsync(int userId, ChangePasswordDto dto)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        if (!_passwordService.VerifyPassword(dto.CurrentPassword, user.PasswordHash, user.PasswordSalt))
            return ServiceResult<bool>.Unauthorized("Current password is incorrect.");

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);
        user.PasswordHash = hash;
        user.PasswordSalt = salt;

        await _userRepository.RevokeAllUserTokensAsync(userId);
        await _userRepository.UpdateAsync(user);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> AdminVerifyUserAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.IsVerified = true;
        user.EmailVerifiedAt = DateTime.UtcNow;
        user.EmailVerificationToken = null;
        user.EmailVerificationTokenExpiresAt = null;
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

    public async Task<ServiceResult<UserProfileDto>> GetProfileAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<UserProfileDto>.NotFound($"User {userId} not found.");

        return ServiceResult<UserProfileDto>.Ok(MapToProfile(user));
    }

    public async Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(
        int userId, UpdateProfileDto request)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<UserProfileDto>.NotFound($"User {userId} not found.");

        if (request.FirstName is not null)
            user.Person!.FirstName = request.FirstName;
        if (request.LastName is not null)
            user.Person!.LastName = request.LastName;
        if (request.PhoneNumber is not null)
            user.Person!.PhoneNumber = request.PhoneNumber;
        if (request.ImageUrl is not null)
            user.Person!.ImageUrl = request.ImageUrl;
        if (request.CityId is not null)
            user.Person!.CityId = request.CityId;

        user.Person!.UpdatedAt = DateTime.UtcNow;
        await _userRepository.UpdateAsync(user);

        return ServiceResult<UserProfileDto>.Ok(MapToProfile(user));
    }

    public async Task<ServiceResult<bool>> DeleteAccountAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        await _userRepository.SoftDeleteAsync(userId);
        await _publishEndpoint.Publish(new UserDeletedMessage(userId, DateTime.UtcNow));
        return ServiceResult<bool>.Ok(true);
    }


    public async Task<ServiceResult<bool>> BanUserAsync(int userId, string reason = "Policy violation")
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

        user.IsBanned = true;
        await _userRepository.UpdateAsync(user);
        await _publishEndpoint.Publish(new UserBannedMessage(
            userId, user.Username, reason, DateTime.UtcNow));
        return ServiceResult<bool>.Ok(true);
    }


    public async Task<ServiceResult<bool>> UnbanUserAsync(int userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user is null)
            return ServiceResult<bool>.NotFound($"User {userId} not found.");

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

    private static UserProfileDto MapToProfile(Domain.Entities.User user) => new()
    {
        UserId = user.PersonId,
        Username = user.Username,
        Email = user.Email,
        FirstName = user.Person!.FirstName,
        LastName = user.Person.LastName,
        ImageUrl = user.Person.ImageUrl,
        Role = user.Role.ToString(),
        IsVerified = user.IsVerified,
        CreatedAt = user.CreatedAt,
        CityId = user.Person.CityId
    };

    // ── Activity Logs ─────────────────────────────────────────────
    public async Task<ServiceResult<List<ActivityLogResponseDto>>> GetUserActivityLogsAsync(
        int userId, int page, int pageSize)
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


    // ── User Preferences ──────────────────────────────────────────
    public async Task<ServiceResult<List<UserPreferenceResponseDto>>> GetUserPreferencesAsync(int userId)
    {
        var prefs = await _userRepository.GetUserPreferencesAsync(userId);
        return ServiceResult<List<UserPreferenceResponseDto>>.Ok(prefs.Select(MapPreference).ToList());
    }

    public async Task<ServiceResult<UserPreferenceResponseDto>> UpsertPreferenceAsync(
        int userId, UpdatePreferenceDto dto)
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
        if (pref is null)
            return ServiceResult<bool>.NotFound("Preference not found.");
        if (pref.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your preference.");

        await _userRepository.DeletePreferenceAsync(pref);
        return ServiceResult<bool>.Ok(true);
    }

    // ── Reports ───────────────────────────────────────────────────
    public async Task<ServiceResult<ReportResponseDto>> CreateReportAsync(
        CreateReportDto dto, int reporterId)
    {
        var report = new Report
        {
            TargetType = dto.TargetType,
            TargetId = dto.TargetId,
            Reason = dto.Reason,
            Description = dto.Description,
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
    ReportStatus? status, int page, int pageSize)
    {
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

    public async Task<ServiceResult<ReportResponseDto>> ResolveReportAsync(
        int reportId, ResolveReportDto dto, int resolvedById)
    {
        var report = await _userRepository.GetReportByIdAsync(reportId);
        if (report is null)
            return ServiceResult<ReportResponseDto>.NotFound("Report not found.");

        if (dto.Action == ReportResolutionAction.Resolve)
            report.Resolve(resolvedById);
        else if (dto.Action == ReportResolutionAction.Dismiss)
            report.Dismiss(resolvedById);
        else
            return ServiceResult<ReportResponseDto>.Fail("Invalid action. Use 'Resolve' or 'Dismiss'.");

        await _userRepository.UpdateReportAsync(report);
        return ServiceResult<ReportResponseDto>.Ok(MapReport(report));
    }

    // ── Mappers ───────────────────────────────────────────────────
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


}
