using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Domain.Entities;
using UserService.Domain.Enums;

namespace UserService.Application.Interfaces.Repositories;

public interface IUserRepository
{
    Task<UserPreference?> GetPreferenceAsync(int userId, int? segmentId, int? genreId, int? subGenreId);
    Task<UserPreference> CreatePreferenceAsync(UserPreference preference);
    Task UpdatePreferenceAsync(UserPreference preference);
    Task<List<UserPreference>> GetUserPreferencesAsync(int userId);
    Task DeletePreferenceAsync(UserPreference preference);

    Task<User?> GetByIdAsync(int userId);
    Task<User?> GetPublicByIdAsync(int userId);
    Task<List<User>> GetPublicByIdsAsync(IEnumerable<int> userIds);

    Task<Report?> GetReportByIdAsync(int reportId);
    Task<PagedResult<Report>> GetReportsAsync(ReportStatus? status, int page, int pageSize);
    Task<List<Report>> GetUserReportsAsync(int userId);
    Task<Report> CreateReportAsync(Report report);
    Task UpdateReportAsync(Report report);
    Task<bool> HasOpenReportAsync(int reporterId, ReportTargetType targetType, int targetId);

    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByUsernameAsync(string username);
    Task<User?> GetByEmailOrUsernameAsync(string identifier);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> UsernameExistsAsync(string username);
    Task<User> CreateAsync(User user, Person person);
    Task UpdateAsync(User user);
    Task SoftDeleteAsync(int userId);
    Task<PagedResult<User>> GetAllAsync(UserFilterDto filter);

    Task<RefreshToken?> GetActiveRefreshTokenAsync(string tokenHash);
    Task CleanupExpiredTokensAsync(int userId);
    Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash);
    Task AddRefreshTokenAsync(RefreshToken token);
    Task RevokeRefreshTokenAsync(string tokenHash);
    Task RevokeAllUserTokensAsync(int userId);

    Task<UserRating?> GetUserRatingAsync(int raterId, int ratedUserId);
    Task<UserRating> CreateUserRatingAsync(UserRating rating);
    Task UpdateUserRatingAsync(UserRating rating);
    Task DeleteUserRatingAsync(UserRating rating);
    Task<(double AverageRating, int RatingsCount)> GetUserRatingSummaryAsync(int userId);
    Task<List<UserRating>> GetUserReviewsAsync(int ratedUserId, int page, int pageSize);
    Task<int> GetUserReviewsCountAsync(int ratedUserId);
}