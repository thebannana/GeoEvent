using Microsoft.EntityFrameworkCore;
using UserService.Application.Common;
using UserService.Application.Interfaces.Repositories;
using UserService.Domain.Entities;
using UserService.Infrastructure.Persistence;

namespace UserService.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly UserDbContext _context;

    public UserRepository(UserDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(int userId) =>
        await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.PersonId == userId);

    public async Task<User?> GetByEmailAsync(string email) =>
        await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Email == email.ToLower());

    public async Task<User?> GetByUsernameAsync(string username) =>
        await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Username == username.ToLower());

    public async Task<User?> GetByEmailOrUsernameAsync(string identifier) =>
        await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u =>
                u.Email == identifier.ToLower() ||
                u.Username == identifier.ToLower());

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

    public async Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash);

    public async Task AddRefreshTokenAsync(RefreshToken token)
    {
        await _context.RefreshTokens.AddAsync(token);
        await _context.SaveChangesAsync();
    }

    public async Task RevokeRefreshTokenAsync(string tokenHash)
    {
        var token = await _context.RefreshTokens
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash);
        if (token is null) return;
        token.Revoke();
        await _context.SaveChangesAsync();
    }

    public async Task RevokeAllUserTokensAsync(int userId)
    {
        await _context.RefreshTokens
            .Where(r => r.UserId == userId && r.RevokedAt == null)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(r => r.RevokedAt, DateTime.UtcNow));
    }

    // ── Activity Logs ─────────────────────────────────────────────
    public async Task<List<ActivityLog>> GetUserActivityLogsAsync(int userId, int page, int pageSize) =>
        await _context.ActivityLogs
            .Where(a => a.UserId == userId)
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

    // ── User Preferences ──────────────────────────────────────────
    public async Task<List<UserPreference>> GetUserPreferencesAsync(int userId) =>
        await _context.UserPreferences
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.Score)
            .ToListAsync();

    public async Task<UserPreference?> GetPreferenceAsync(int userId, int? segmentId, int? genreId) =>
        await _context.UserPreferences
            .FirstOrDefaultAsync(p =>
                p.UserId == userId &&
                p.SegmentId == segmentId &&
                p.GenreId == genreId);

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

    // ── Reports ───────────────────────────────────────────────────
    public async Task<Report?> GetReportByIdAsync(int reportId) =>
        await _context.Reports
            .Include(r => r.Reporter)
            .Include(r => r.ResolvedBy)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

    public async Task<PagedResult<Report>> GetReportsAsync(string? status, int page, int pageSize)
    {
        var query = _context.Reports
            .Include(r => r.Reporter)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(r => r.Status == status);

        query = query.OrderByDescending(r => r.ReportId);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Report>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<Report>> GetUserReportsAsync(int userId) =>
        await _context.Reports
            .Where(r => r.ReporterId == userId)
            .OrderByDescending(r => r.ReportId)
            .ToListAsync();

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

}
