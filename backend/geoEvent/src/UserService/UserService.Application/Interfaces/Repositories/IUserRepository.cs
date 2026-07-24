using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Domain.Entities;
using UserService.Domain.Enums;

namespace UserService.Application.Interfaces.Repositories;

public interface IUserRepository
{
    Task<UserRating?> GetUserReviewByIdAsync(int reviewId);
    Task<User?> GetByIdAsync(int userId);
    Task<User?> GetByIdForUpdateAsync(int userId);
    Task<User?> GetPublicByIdAsync(int userId);
    Task<List<User>> GetPublicByIdsAsync(IEnumerable<int> userIds);

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
    Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash);
    Task AddRefreshTokenAsync(RefreshToken token);
    Task RevokeRefreshTokenAsync(string tokenHash);
    Task RevokeAllUserTokensAsync(int userId);
    Task CleanupExpiredTokensAsync(int userId);

    Task<PasswordResetToken?> GetActivePasswordResetTokenAsync(int userId, string tokenHash);
    Task InvalidateActivePasswordResetTokensAsync(int userId);
    Task CreatePasswordResetTokenAsync(PasswordResetToken token);
    Task MarkPasswordResetTokenUsedAsync(PasswordResetToken token);

    Task<List<UserPreference>> GetUserPreferencesAsync(int userId);
    Task<UserPreference?> GetPreferenceAsync(int userId, int? segmentId, int? genreId, int? subGenreId);
    Task<UserPreference?> GetPreferenceForUpdateAsync(int userId, int? segmentId, int? genreId, int? subGenreId);
    Task<UserPreference> CreatePreferenceAsync(UserPreference preference);
    Task UpdatePreferenceAsync(UserPreference preference);
    Task DeletePreferenceAsync(UserPreference preference);

    Task<UserRating?> GetUserRatingAsync(int raterId, int ratedUserId);
    Task<UserRating?> GetUserRatingForUpdateAsync(int raterId, int ratedUserId);
    Task CreateUserRatingAsync(UserRating rating);
    Task UpdateUserRatingAsync(UserRating rating);
    Task DeleteUserRatingAsync(UserRating rating);
    Task<(double AverageRating, int RatingsCount)> GetUserRatingSummaryAsync(int userId);
    Task<Dictionary<int, (double AverageRating, int RatingsCount)>> GetUserRatingSummariesAsync(IEnumerable<int> userIds);
    Task<List<UserRating>> GetUserReviewsAsync(int ratedUserId, int page, int pageSize);
    Task<int> GetUserReviewsCountAsync(int ratedUserId);

    Task<Report?> GetReportByIdAsync(int reportId);
    Task<Report?> GetReportByIdForUpdateAsync(int reportId);
    Task<PagedResult<Report>> GetReportsAsync(
        ReportStatus? status,
        ReportTargetType? targetType,
        string? search,
        string? sortBy,
        bool descending,
        int page,
        int pageSize);
    Task<PagedResult<Report>> GetUserReportsAsync(int userId, int page, int pageSize);
    Task<Report> CreateReportAsync(Report report);
    Task UpdateReportAsync(Report report);
    Task<bool> HasOpenReportAsync(int reporterId, ReportTargetType targetType, int targetId);

    Task<int> GetActiveUsersCountAsync(DateTime activeSinceUtc, CancellationToken cancellationToken = default);
    Task<int> GetReportsCountAsync(CancellationToken cancellationToken = default);
    Task<List<DashboardPreferenceAggregateRawDto>> GetTopSegmentsRawAsync(int take, CancellationToken cancellationToken = default);
    Task<List<DashboardPreferenceAggregateRawDto>> GetTopGenresRawAsync(int take, CancellationToken cancellationToken = default);
    Task<List<DashboardPreferenceAggregateRawDto>> GetTopSubGenresRawAsync(int take, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}