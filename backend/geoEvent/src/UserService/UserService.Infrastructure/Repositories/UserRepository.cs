using Microsoft.EntityFrameworkCore;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Repositories;
using UserService.Domain.Entities;
using UserService.Domain.Enums;
using UserService.Infrastructure.Persistence;

namespace UserService.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly UserDbContext _context;

    public UserRepository(UserDbContext context)
    {
        _context = context;
    }

    public async Task<UserRating?> GetUserRatingAsync(int raterId, int ratedUserId) =>
    await _context.Set<UserRating>()
        .FirstOrDefaultAsync(x => x.RaterId == raterId && x.RatedUserId == ratedUserId);

    public async Task<UserRating> CreateUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Add(rating);
        await _context.SaveChangesAsync();
        return rating;
    }

    public async Task UpdateUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Update(rating);
        await _context.SaveChangesAsync();
    }

    public async Task<List<UserPreference>> GetUserPreferencesAsync(int userId)
    => await _context.UserPreferences
        .Where(p => p.UserId == userId)
        .OrderByDescending(p => p.Score)
        .ToListAsync();

    public async Task<UserPreference> CreatePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Add(preference);
        await _context.SaveChangesAsync();
        return preference;
    }

    public async Task UpdatePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Update(preference);
        await _context.SaveChangesAsync();
    }

    public async Task DeletePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Remove(preference);
        await _context.SaveChangesAsync();
    }

    public async Task<UserPreference?> GetPreferenceAsync(
    int userId,
    int? segmentId,
    int? genreId,
    int? subGenreId)
    => await _context.UserPreferences.FirstOrDefaultAsync(p =>
        p.UserId == userId &&
        p.SegmentId == segmentId &&
        p.GenreId == genreId &&
        p.SubGenreId == subGenreId);

    public async Task DeleteUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Remove(rating);
        await _context.SaveChangesAsync();
    }

    public async Task<(double AverageRating, int RatingsCount)> GetUserRatingSummaryAsync(int userId)
    {
        var query = _context.Set<UserRating>().Where(x => x.RatedUserId == userId);

        var count = await query.CountAsync();
        if (count == 0)
            return (0, 0);

        var avg = await query.AverageAsync(x => x.Value);
        return (Math.Round(avg, 2), count);
    }

    public async Task<List<UserRating>> GetUserReviewsAsync(int ratedUserId, int page, int pageSize) =>
        await _context.Set<UserRating>()
            .Include(x => x.Rater)
            .ThenInclude(x => x!.Person)
            .Where(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment))
            .OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

    public async Task<int> GetUserReviewsCountAsync(int ratedUserId) =>
        await _context.Set<UserRating>()
            .CountAsync(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment));
    public async Task<User?> GetByIdAsync(int userId) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.PersonId == userId);

    public async Task<User?> GetByEmailAsync(string email) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.Email == email.ToLower());

    public async Task<User?> GetByUsernameAsync(string username) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.Username == username.ToLower());

    public async Task<User?> GetByEmailOrUsernameAsync(string identifier) =>
        await _context.Users.Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Email == identifier.ToLower() || u.Username == identifier.ToLower());

    public async Task<bool> EmailExistsAsync(string email) =>
        await _context.Users.AnyAsync(u => u.Email == email.ToLower());

    public async Task<bool> UsernameExistsAsync(string username) =>
        await _context.Users.AnyAsync(u => u.Username == username.ToLower());

    public async Task<User> CreateAsync(User user, Person person)
    {
        await _context.People.AddAsync(person);
        await _context.SaveChangesAsync();
        user.PersonId = person.PersonId;
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }

    public async Task SoftDeleteAsync(int userId)
    {
        var user = await GetByIdAsync(userId);
        if (user is null) return;
        user.SoftDelete();
        await _context.SaveChangesAsync();
    }

    public async Task<PagedResult<User>> GetAllAsync(UserFilterDto filter)
    {
        var query = _context.Users.Include(u => u.Person).AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            query = query.Where(u => u.Username.Contains(filter.Search) || u.Email.Contains(filter.Search));
        }

        if (!string.IsNullOrWhiteSpace(filter.Role))
        {
            query = query.Where(u => u.Role.ToString() == filter.Role);
        }

        if (filter.IsBanned.HasValue)
        {
            query = query.Where(u => u.IsBanned == filter.IsBanned.Value);
        }

        if (filter.IsVerified.HasValue)
        {
            query = query.Where(u => u.IsVerified == filter.IsVerified.Value);
        }

        var total = await query.CountAsync();
        var items = await query.OrderByDescending(u => u.CreatedAt)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<User>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<RefreshToken?> GetActiveRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens
            .Include(r => r.User).ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash && r.RevokedAt == null && r.ExpiresAt > DateTime.UtcNow);

    public async Task CleanupExpiredTokensAsync(int userId) =>
        await _context.RefreshTokens.Where(r => r.UserId == userId && r.ExpiresAt <= DateTime.UtcNow).ExecuteDeleteAsync();

    public async Task<User?> GetByResetTokenAsync(string token) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.PasswordResetToken == token);

    public async Task<User?> GetByVerificationTokenAsync(string token) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.EmailVerificationToken == token);

    public async Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens.Include(r => r.User).ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash);

    public async Task AddRefreshTokenAsync(RefreshToken token)
    {
        await _context.RefreshTokens.AddAsync(token);
        await _context.SaveChangesAsync();
    }

    public async Task RevokeRefreshTokenAsync(string tokenHash)
    {
        var token = await _context.RefreshTokens.FirstOrDefaultAsync(r => r.TokenHash == tokenHash);
        if (token is null) return;
        token.Revoke();
        await _context.SaveChangesAsync();
    }

    public async Task RevokeAllUserTokensAsync(int userId) =>
        await _context.RefreshTokens.Where(r => r.UserId == userId && r.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(r => r.RevokedAt, DateTime.UtcNow));

    public async Task<List<ActivityLog>> GetUserActivityLogsAsync(int userId, int page, int pageSize) =>
        await _context.ActivityLogs.Where(a => a.UserId == userId)
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

    public async Task<ActivityLog> CreateActivityLogAsync(ActivityLog log)
    {
        _context.ActivityLogs.Add(log);
        await _context.SaveChangesAsync();
        return log;
    }

    public async Task<Report?> GetReportByIdAsync(int reportId) =>
        await _context.Reports.Include(r => r.Reporter).Include(r => r.ResolvedBy)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

    public async Task<PagedResult<Report>> GetReportsAsync(ReportStatus? status, int page, int pageSize)
    {
        var query = _context.Reports.Include(r => r.Reporter).AsQueryable();

        if (status.HasValue)
        {
            query = query.Where(r => r.Status == status.Value);
        }

        query = query.OrderByDescending(r => r.ReportId);

        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return new PagedResult<Report>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<Report>> GetUserReportsAsync(int userId) =>
        await _context.Reports.Where(r => r.ReporterId == userId).OrderByDescending(r => r.ReportId).ToListAsync();

    public async Task<Report> CreateReportAsync(Report report)
    {
        _context.Reports.Add(report);
        await _context.SaveChangesAsync();
        return report;
    }

    public async Task UpdateReportAsync(Report report)
    {
        _context.Reports.Update(report);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> HasOpenReportAsync(int reporterId, ReportTargetType targetType, int targetId) =>
    await _context.Reports.AnyAsync(r =>
        r.ReporterId == reporterId &&
        r.TargetType == targetType &&
        r.TargetId == targetId &&
        (r.Status == ReportStatus.Pending || r.Status == ReportStatus.UnderReview));

    public async Task<User?> GetPublicByIdAsync(int userId) =>
        await _context.Users.Include(u => u.Person).FirstOrDefaultAsync(u => u.PersonId == userId);

    public async Task<List<User>> GetPublicByIdsAsync(IEnumerable<int> userIds)
    {
        var ids = userIds.Distinct().ToList();
        return await _context.Users.Include(u => u.Person).Where(u => ids.Contains(u.PersonId)).ToListAsync();
    }
}