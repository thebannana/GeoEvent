using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Domain.Enums;

namespace UserService.Application.Interfaces.Services;

public interface IUserService
{
    Task<ServiceResult<InternalReviewLookupDto>> GetInternalReviewLookupAsync(int reviewId);
    Task<ServiceResult<ReportResponseDto>> CreateReportAsync(CreateReportDto dto, int reporterId);
    Task<ServiceResult<PagedResult<ReportResponseDto>>> GetUserReportsAsync(int userId, int page, int pageSize);

    Task<ServiceResult<PagedResult<AdminReportResponseDto>>> GetAllReportsAsync(AdminReportsQueryDto query);
    Task<ServiceResult<AdminReportResponseDto>> GetReportByIdAsync(int reportId);
    Task<ServiceResult<AdminReportResponseDto>> UpdateReportStatusAsync(int reportId, UpdateReportStatusDto dto, int adminUserId);

    Task<ServiceResult<UserProfileDto>> GetProfileAsync(int userId);
    Task<ServiceResult<PublicUserProfileDto>> GetPublicProfileAsync(int userId, int? requesterId = null);
    Task<List<CommentUserProfileDto>> GetCommentUserProfilesAsync(IEnumerable<int> ids);
    Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(int userId, UpdateProfileDto request);
    Task<ServiceResult<bool>> AdminDeleteUserAsync(int userId);
    Task<ServiceResult<bool>> DeleteAccountAsync(int userId);
    Task<ServiceResult<bool>> BanUserAsync(int userId, string reason = "Policy violation");
    Task<ServiceResult<bool>> UnbanUserAsync(int userId);
    Task<ServiceResult<bool>> ChangePasswordAsync(int userId, ChangePasswordDto dto);
    Task<ServiceResult<PagedResult<UserProfileDto>>> GetAllUsersAsync(UserFilterDto filter);
    Task<ServiceResult<PagedResult<UserPreferenceResponseDto>>> GetUserPreferencesAsync(int userId, PreferencesFilterDto filter);
    Task<ServiceResult<UserPreferenceResponseDto>> UpsertPreferenceAsync(int userId, UpdatePreferenceDto dto);
    Task<ServiceResult<bool>> DeletePreferenceAsync(int userId, int prefId);
    Task<ServiceResult<PagedResult<UserReviewResponseDto>>> GetUserReviewsAsync(int userId, int page, int pageSize);
    Task<ServiceResult<List<PublicUserProfileDto>>> GetPublicProfilesAsync(IEnumerable<int> userIds);
    Task<ServiceResult<AdminUserProfileDetailsDto>> GetAdminProfileAsync(int userId, int? requesterId = null);
    Task<ServiceResult<bool>> RateUserAsync(int ratedUserId, int raterId, RateUserDto dto);
    Task<ServiceResult<bool>> DeleteUserReviewAsync(int ratedUserId, int raterId);
    Task<ServiceResult<UserProfileDto>> AdminUpdateUserAsync(int userId, AdminUpdateUserDto request);
    Task<ServiceResult<AdminUsersDashboardStatsDto>> GetAdminUsersDashboardStatsAsync();
    Task ApplyInteractionPreferenceAsync(int userId, int eventId, int? segmentId, int? genreId, int? subGenreId, string interactionType, DateTime occurredAt);
}