using UserService.Domain.Entities;
using UserService.Application.Common;

namespace UserService.Application.Interfaces.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int userId);
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByUsernameAsync(string username);
    Task<User?> GetByEmailOrUsernameAsync(string identifier);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> UsernameExistsAsync(string username);
    Task<User> CreateAsync(User user, Person person);
    Task UpdateAsync(User user);
    Task SoftDeleteAsync(int userId);

    // Refresh tokens
    Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash);
    Task AddRefreshTokenAsync(RefreshToken token);
    Task RevokeRefreshTokenAsync(string tokenHash);
    Task RevokeAllUserTokensAsync(int userId);

    // ── Activity Logs ─────────────────────────────────────────────
    Task<List<ActivityLog>> GetUserActivityLogsAsync(int userId, int page, int pageSize);
    Task<ActivityLog> CreateActivityLogAsync(ActivityLog log);

    // ── User Preferences ──────────────────────────────────────────
    Task<List<UserPreference>> GetUserPreferencesAsync(int userId);
    Task<UserPreference?> GetPreferenceAsync(int userId, int? segmentId, int? genreId);
    Task<UserPreference> CreatePreferenceAsync(UserPreference preference);
    Task UpdatePreferenceAsync(UserPreference preference);
    Task DeletePreferenceAsync(UserPreference preference);

    // ── Reports ───────────────────────────────────────────────────
    Task<Report?> GetReportByIdAsync(int reportId);
    Task<PagedResult<Report>> GetReportsAsync(string? status, int page, int pageSize);
    Task<List<Report>> GetUserReportsAsync(int userId);
    Task<Report> CreateReportAsync(Report report);
    Task UpdateReportAsync(Report report);

}
