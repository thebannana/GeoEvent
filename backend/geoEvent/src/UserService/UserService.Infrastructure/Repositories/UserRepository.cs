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
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 100;
    private const int MaxReviewPageSize = 50;

    private readonly UserDbContext _context;

    public UserRepository(UserDbContext context)
    {
        _context = context;
    }

    private static (int Page, int PageSize) NormalizePaging(int page, int pageSize, int maxPageSize = MaxPageSize)
    {
        var normalizedPage = page <= 0 ? 1 : page;
        var normalizedPageSize = pageSize <= 0 ? DefaultPageSize : Math.Min(pageSize, maxPageSize);
        return (normalizedPage, normalizedPageSize);
    }

    public async Task<List<UserPreference>> GetUserPreferencesAsync(int userId) =>
        await _context.UserPreferences
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .ToListAsync();

    public async Task<UserPreference?> GetPreferenceAsync(
        int userId,
        int? segmentId,
        int? genreId,
        int? subGenreId) =>
        await _context.UserPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(p =>
                p.UserId == userId &&
                p.SegmentId == segmentId &&
                p.GenreId == genreId &&
                p.SubGenreId == subGenreId);

    public async Task<UserRating?> GetUserRatingAsync(int raterId, int ratedUserId) =>
        await _context.Set<UserRating>()
            .AsNoTracking()
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

    public async Task DeleteUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Remove(rating);
        await _context.SaveChangesAsync();
    }

    public async Task<(double AverageRating, int RatingsCount)> GetUserRatingSummaryAsync(int userId)
    {
        var query = _context.Set<UserRating>()
            .AsNoTracking()
            .Where(x => x.RatedUserId == userId);

        var count = await query.CountAsync();
        if (count == 0)
            return (0, 0);

        var avg = await query.AverageAsync(x => x.Value);
        return (Math.Round(avg, 2), count);
    }

    public async Task<List<UserRating>> GetUserReviewsAsync(int ratedUserId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize, MaxReviewPageSize);

        return await _context.Set<UserRating>()
            .AsNoTracking()
            .Include(x => x.Rater)
            .ThenInclude(x => x!.Person)
            .Where(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment))
            .OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();
    }

    public async Task<int> GetUserReviewsCountAsync(int ratedUserId) =>
        await _context.Set<UserRating>()
            .AsNoTracking()
            .CountAsync(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment));

    public async Task<User?> GetByIdAsync(int userId) =>
        await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.PersonId == userId);

    public async Task<User?> GetByEmailAsync(string email)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        return await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Email == normalizedEmail);
    }

    public async Task<User?> GetByUsernameAsync(string username)
    {
        var normalizedUsername = username.Trim().ToLowerInvariant();

        return await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Username == normalizedUsername);
    }

    public async Task<User?> GetByEmailOrUsernameAsync(string identifier)
    {
        var normalizedIdentifier = identifier.Trim().ToLowerInvariant();

        return await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.Email == normalizedIdentifier || u.Username == normalizedIdentifier);
    }

    public async Task<bool> EmailExistsAsync(string email)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        return await _context.Users.AsNoTracking().AnyAsync(u => u.Email == normalizedEmail);
    }

    public async Task<bool> UsernameExistsAsync(string username)
    {
        var normalizedUsername = username.Trim().ToLowerInvariant();
        return await _context.Users.AsNoTracking().AnyAsync(u => u.Username == normalizedUsername);
    }

    public async Task<User> CreateAsync(User user, Person person)
    {
        await _context.People.AddAsync(person);
        user.Person = person;
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
        var user = await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.PersonId == userId);

        if (user is null)
            return;

        user.SoftDelete();
        await _context.SaveChangesAsync();
    }

    public async Task<PagedResult<User>> GetAllAsync(UserFilterDto filter)
    {
        filter ??= new UserFilterDto();
        var (page, pageSize) = NormalizePaging(filter.Page, filter.PageSize);

        var query = _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var term = filter.Search.Trim();
            query = query.Where(u => u.Username.Contains(term) || u.Email.Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(filter.Role))
        {
            query = query.Where(u => u.Role.ToString() == filter.Role);
        }

        if (filter.IsBanned.HasValue)
        {
            query = query.Where(u => u.IsBanned == filter.IsBanned.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<User>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<RefreshToken?> GetActiveRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens
            .Include(r => r.User)
            .ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash && r.RevokedAt == null && r.ExpiresAt > DateTime.UtcNow);

    public async Task CleanupExpiredTokensAsync(int userId) =>
        await _context.RefreshTokens
            .Where(r => r.UserId == userId && r.ExpiresAt <= DateTime.UtcNow)
            .ExecuteDeleteAsync();

    public async Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens
            .Include(r => r.User)
            .ThenInclude(u => u!.Person)
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
        await _context.RefreshTokens
            .Where(r => r.UserId == userId && r.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(r => r.RevokedAt, DateTime.UtcNow));

    public async Task<Report?> GetReportByIdAsync(int reportId) =>
        await _context.Reports
            .AsNoTracking()
            .Include(r => r.Reporter)
            .Include(r => r.ResolvedBy)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

    public async Task<PagedResult<Report>> GetReportsAsync(ReportStatus? status, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

        var query = _context.Reports
            .AsNoTracking()
            .Include(r => r.Reporter)
            .AsQueryable();

        if (status.HasValue)
        {
            query = query.Where(r => r.Status == status.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReportId)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<Report>
        {
            Items = items,
            TotalCount = total,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

    public async Task<PagedResult<Report>> GetUserReportsAsync(int userId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize, 50);

        var query = _context.Reports
            .AsNoTracking()
            .Where(r => r.ReporterId == userId);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReportId)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<Report>
        {
            Items = items,
            TotalCount = total,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

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
        await _context.Reports
            .AsNoTracking()
            .AnyAsync(r =>
                r.ReporterId == reporterId &&
                r.TargetType == targetType &&
                r.TargetId == targetId &&
                (r.Status == ReportStatus.Pending || r.Status == ReportStatus.UnderReview));

    public async Task<User?> GetPublicByIdAsync(int userId) =>
        await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.PersonId == userId);

    public async Task<List<User>> GetPublicByIdsAsync(IEnumerable<int> userIds)
    {
        var ids = userIds.Distinct().ToList();

        return await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .Where(u => ids.Contains(u.PersonId))
            .ToListAsync();
    }
}