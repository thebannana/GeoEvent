using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Domain.Enums;

namespace UserService.Application.Interfaces.Services;

public interface IUserService
{
    Task<ServiceResult<UserProfileDto>> GetProfileAsync(int userId);
    Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileDto request);
    Task<ServiceResult<bool>> DeleteAccountAsync(int userId);
    Task<ServiceResult<bool>> BanUserAsync(int userId, string reason = "Policy violation");
    Task<ServiceResult<bool>> UnbanUserAsync(int userId);
    Task<ServiceResult<bool>> VerifyEmailAsync(string token);
    Task<ServiceResult<bool>> ChangePasswordAsync(int userId, ChangePasswordDto dto);
    Task<ServiceResult<PagedResult<UserProfileDto>>> GetAllUsersAsync(UserFilterDto filter);
    Task<ServiceResult<bool>> AdminVerifyUserAsync(int userId);

    Task<ServiceResult<List<ActivityLogResponseDto>>> GetUserActivityLogsAsync(int userId, int page, int pageSize);
    Task<ServiceResult<ActivityLogResponseDto>> LogActivityAsync(
        int userId,
        ActivityActionType actionType,
        ActivityTargetType targetType,
        int targetId,
        string metadata,
        Guid sessionId);

    Task<ServiceResult<List<UserPreferenceResponseDto>>> GetUserPreferencesAsync(int userId);
    Task<ServiceResult<UserPreferenceResponseDto>> UpsertPreferenceAsync(int userId, UpdatePreferenceDto dto);
    Task<ServiceResult<bool>> DeletePreferenceAsync(int userId, int prefId);

    Task<ServiceResult<ReportResponseDto>> CreateReportAsync(CreateReportDto dto, int reporterId);
    Task<ServiceResult<List<ReportResponseDto>>> GetUserReportsAsync(int userId);
    Task<ServiceResult<PagedResult<ReportResponseDto>>> GetAllReportsAsync(ReportStatus? status, int page, int pageSize);
    Task<ServiceResult<ReportResponseDto>> ResolveReportAsync(int reportId, ResolveReportDto dto, int resolvedById);

    Task<ServiceResult<PublicUserProfileDto>> GetPublicProfileAsync(int userId);
    Task<ServiceResult<List<PublicUserProfileDto>>> GetPublicProfilesAsync(IEnumerable<int> userIds);
}