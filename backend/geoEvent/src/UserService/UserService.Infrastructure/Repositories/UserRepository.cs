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
    private const int MaxPageSize = 100;
    private const int MaxReviewPageSize = 50;
    private const int MaxUserReportPageSize = 50;

    private readonly UserDbContext _context;

    public UserRepository(UserDbContext context)
    {
        _context = context;
    }

    public async Task<UserRating?> GetUserReviewByIdAsync(int reviewId)
    {
        return await _context.Set<UserRating>()
            .AsNoTracking()
            .Include(x => x.Rater)
                .ThenInclude(x => x!.Person)
            .FirstOrDefaultAsync(x => x.RatingId == reviewId);
    }

    public async Task<Report?> GetReportByIdAsync(int reportId)
    {
        return await _context.Reports
            .AsNoTracking()
            .Include(r => r.Reporter)
                .ThenInclude(u => u!.Person)
            .Include(r => r.ResolvedBy)
                .ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);
    }

    public async Task<Report?> GetReportByIdForUpdateAsync(int reportId)
    {
        return await _context.Reports
            .Include(r => r.Reporter)
                .ThenInclude(u => u!.Person)
            .Include(r => r.ResolvedBy)
                .ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);
    }

    public async Task<PagedResult<Report>> GetReportsAsync(
        ReportStatus? status,
        ReportTargetType? targetType,
        string? search,
        string? sortBy,
        bool descending,
        int page,
        int pageSize)
    {
        ValidatePaging(page, pageSize, MaxPageSize);

        var query = _context.Reports
            .AsNoTracking()
            .Include(r => r.Reporter)
                .ThenInclude(u => u!.Person)
            .Include(r => r.ResolvedBy)
                .ThenInclude(u => u!.Person)
            .AsQueryable();

        if (status.HasValue)
            query = query.Where(r => r.Status == status.Value);

        if (targetType.HasValue)
            query = query.Where(r => r.TargetType == targetType.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();

            query = query.Where(r =>
                r.ReportId.ToString().Contains(term) ||
                r.Reason.Contains(term, StringComparison.CurrentCultureIgnoreCase) ||
                (r.Description != null &&
                 r.Description.Contains(term, StringComparison.CurrentCultureIgnoreCase)) ||
                (r.Reporter != null &&
                 r.Reporter.Username.Contains(term, StringComparison.CurrentCultureIgnoreCase)) ||
                (r.Reporter != null &&
                 r.Reporter.Person != null &&
                 (
                     (r.Reporter.Person.FirstName + " " +
                      r.Reporter.Person.LastName)
                     .Trim()
.Contains(term, StringComparison.CurrentCultureIgnoreCase)
                 )) ||
                (r.TargetId.HasValue &&
                 r.TargetId.Value.ToString().Contains(term)));
        }

        var normalizedSort = sortBy?.Trim().ToLowerInvariant();

        query = normalizedSort switch
        {
            "createdat" => descending
                ? query.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.ReportId)
                : query.OrderBy(r => r.CreatedAt).ThenBy(r => r.ReportId),

            "status" => descending
                ? query.OrderByDescending(r => r.Status).ThenByDescending(r => r.ReportId)
                : query.OrderBy(r => r.Status).ThenBy(r => r.ReportId),

            "type" => descending
                ? query.OrderByDescending(r => r.TargetType).ThenByDescending(r => r.ReportId)
                : query.OrderBy(r => r.TargetType).ThenBy(r => r.ReportId),

            "reporter" => descending
                ? query.OrderByDescending(r => r.Reporter != null ? r.Reporter.Username : string.Empty)
                       .ThenByDescending(r => r.ReportId)
                : query.OrderBy(r => r.Reporter != null ? r.Reporter.Username : string.Empty)
                       .ThenBy(r => r.ReportId),

            _ => descending
                ? query.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.ReportId)
                : query.OrderBy(r => r.CreatedAt).ThenBy(r => r.ReportId)
        };

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

    public async Task<PagedResult<Report>> GetUserReportsAsync(int userId, int page, int pageSize)
    {
        ValidatePaging(page, pageSize, MaxUserReportPageSize);

        var query = _context.Reports
            .AsNoTracking()
            .Where(r => r.ReporterId == userId);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReportId)
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

    public Task<Report> CreateReportAsync(Report report)
    {
        _context.Reports.Add(report);
        return Task.FromResult(report);
    }

    public Task UpdateReportAsync(Report report)
    {
        _context.Reports.Update(report);
        return Task.CompletedTask;
    }

    public async Task<bool> HasOpenReportAsync(int reporterId, ReportTargetType targetType, int targetId) =>
        await _context.Reports
            .AsNoTracking()
            .AnyAsync(r =>
                r.ReporterId == reporterId &&
                r.TargetType == targetType &&
                r.TargetId == targetId &&
                (r.Status == ReportStatus.Pending || r.Status == ReportStatus.UnderReview));

    public async Task<int> GetActiveUsersCountAsync(
    DateTime activeSinceUtc,
    CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .AsNoTracking()
            .Where(u =>
                u.Person != null &&
                !u.Person.IsDeleted &&
                !u.IsBanned &&
                u.Role != UserRole.Admin &&
                u.LastLoginAt.HasValue &&
                u.LastLoginAt.Value >= activeSinceUtc)
            .CountAsync(cancellationToken);
    }

    public async Task<int> GetReportsCountAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Reports
            .AsNoTracking()
            .CountAsync(cancellationToken);
    }

    public async Task<List<DashboardPreferenceAggregateRawDto>> GetTopSegmentsRawAsync(
        int take,
        CancellationToken cancellationToken = default)
    {
        return await _context.UserPreferences
            .AsNoTracking()
            .Where(p =>
                p.UserId != null &&
                p.SegmentId != null &&
                p.GenreId == null &&
                p.SubGenreId == null)
            .GroupBy(p => p.SegmentId!.Value)
            .Select(g => new DashboardPreferenceAggregateRawDto
            {
                Id = g.Key,
                TotalScore = Math.Round(g.Sum(x => x.Score), 2),
                UserCount = g.Select(x => x.UserId!.Value).Distinct().Count()
            })
            .OrderByDescending(x => x.TotalScore)
            .ThenByDescending(x => x.UserCount)
            .Take(take)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<DashboardPreferenceAggregateRawDto>> GetTopGenresRawAsync(
        int take,
        CancellationToken cancellationToken = default)
    {
        return await _context.UserPreferences
            .AsNoTracking()
            .Where(p =>
                p.UserId != null &&
                p.GenreId != null &&
                p.SubGenreId == null)
            .GroupBy(p => p.GenreId!.Value)
            .Select(g => new DashboardPreferenceAggregateRawDto
            {
                Id = g.Key,
                TotalScore = Math.Round(g.Sum(x => x.Score), 2),
                UserCount = g.Select(x => x.UserId!.Value).Distinct().Count()
            })
            .OrderByDescending(x => x.TotalScore)
            .ThenByDescending(x => x.UserCount)
            .Take(take)
            .ToListAsync(cancellationToken);
    }

    public async Task<List<DashboardPreferenceAggregateRawDto>> GetTopSubGenresRawAsync(
        int take,
        CancellationToken cancellationToken = default)
    {
        return await _context.UserPreferences
            .AsNoTracking()
            .Where(p =>
                p.UserId != null &&
                p.SubGenreId != null)
            .GroupBy(p => p.SubGenreId!.Value)
            .Select(g => new DashboardPreferenceAggregateRawDto
            {
                Id = g.Key,
                TotalScore = Math.Round(g.Sum(x => x.Score), 2),
                UserCount = g.Select(x => x.UserId!.Value).Distinct().Count()
            })
            .OrderByDescending(x => x.TotalScore)
            .ThenByDescending(x => x.UserCount)
            .Take(take)
            .ToListAsync(cancellationToken);
    }
    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _context.SaveChangesAsync(cancellationToken);

    private static void ValidatePaging(int page, int pageSize, int maxPageSize)
    {
        if (page <= 0)
            throw new ArgumentOutOfRangeException(nameof(page), "Page must be greater than 0.");

        if (pageSize <= 0 || pageSize > maxPageSize)
        {
            throw new ArgumentOutOfRangeException(
                nameof(pageSize),
                $"PageSize must be between 1 and {maxPageSize}.");
        }
    }

    public async Task<User?> GetByIdAsync(int userId) =>
    await _context.Users
        .AsNoTracking()
        .Include(u => u.Person)
        .FirstOrDefaultAsync(u =>
            u.PersonId == userId &&
            u.Person != null &&
            !u.Person.IsDeleted);

    public async Task<User?> GetByIdForUpdateAsync(int userId) =>
        await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u =>
                u.PersonId == userId &&
                u.Person != null &&
                !u.Person.IsDeleted);

    public async Task<User?> GetPublicByIdAsync(int userId) =>
        await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u =>
                u.PersonId == userId &&
                u.Person != null &&
                !u.Person.IsDeleted);

    public async Task<List<User>> GetPublicByIdsAsync(IEnumerable<int> userIds)
    {
        var ids = userIds
            .Where(x => x > 0)
            .Distinct()
            .ToList();

        if (ids.Count == 0)
            return [];

        return await _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .Where(u =>
                ids.Contains(u.PersonId) &&
                u.Person != null &&
                !u.Person.IsDeleted)
            .ToListAsync();
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

    public async Task<UserPreference?> GetPreferenceForUpdateAsync(
        int userId,
        int? segmentId,
        int? genreId,
        int? subGenreId) =>
        await _context.UserPreferences
            .FirstOrDefaultAsync(p =>
                p.UserId == userId &&
                p.SegmentId == segmentId &&
                p.GenreId == genreId &&
                p.SubGenreId == subGenreId);

    public async Task<UserRating?> GetUserRatingAsync(int raterId, int ratedUserId) =>
        await _context.Set<UserRating>()
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.RaterId == raterId && x.RatedUserId == ratedUserId);

    public async Task<UserRating?> GetUserRatingForUpdateAsync(int raterId, int ratedUserId) =>
        await _context.Set<UserRating>()
            .FirstOrDefaultAsync(x => x.RaterId == raterId && x.RatedUserId == ratedUserId);

    public Task CreateUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Add(rating);
        return Task.CompletedTask;
    }

    public Task UpdateUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Update(rating);
        return Task.CompletedTask;
    }

    public Task DeleteUserRatingAsync(UserRating rating)
    {
        _context.Set<UserRating>().Remove(rating);
        return Task.CompletedTask;
    }

    public async Task<(double AverageRating, int RatingsCount)> GetUserRatingSummaryAsync(int userId)
    {
        var result = await _context.Set<UserRating>()
            .AsNoTracking()
            .Where(x => x.RatedUserId == userId)
            .GroupBy(x => x.RatedUserId)
            .Select(g => new
            {
                AverageRating = g.Average(x => x.Value),
                RatingsCount = g.Count()
            })
            .FirstOrDefaultAsync();

        return result is null
            ? (0, 0)
            : (Math.Round(result.AverageRating, 2), result.RatingsCount);
    }

    public async Task<Dictionary<int, (double AverageRating, int RatingsCount)>> GetUserRatingSummariesAsync(IEnumerable<int> userIds)
    {
        var ids = userIds
            .Where(x => x > 0)
            .Distinct()
            .ToList();

        if (ids.Count == 0)
            return [];

        var summaries = await _context.Set<UserRating>()
            .AsNoTracking()
            .Where(x => ids.Contains(x.RatedUserId))
            .GroupBy(x => x.RatedUserId)
            .Select(g => new
            {
                UserId = g.Key,
                AverageRating = g.Average(x => x.Value),
                RatingsCount = g.Count()
            })
            .ToListAsync();

        return summaries.ToDictionary(
            x => x.UserId,
            x => (Math.Round(x.AverageRating, 2), x.RatingsCount));
    }

    public async Task<List<UserRating>> GetUserReviewsAsync(int ratedUserId, int page, int pageSize)
    {
        ValidatePaging(page, pageSize, MaxReviewPageSize);

        return await _context.Set<UserRating>()
            .AsNoTracking()
            .Include(x => x.Rater)
            .ThenInclude(x => x!.Person)
            .Where(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment))
            .OrderByDescending(x => x.UpdatedAt ?? x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> GetUserReviewsCountAsync(int ratedUserId) =>
        await _context.Set<UserRating>()
            .AsNoTracking()
            .CountAsync(x => x.RatedUserId == ratedUserId && !string.IsNullOrWhiteSpace(x.Comment));

    public Task<UserPreference> CreatePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Add(preference);
        return Task.FromResult(preference);
    }

    public Task UpdatePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Update(preference);
        return Task.CompletedTask;
    }

    public Task DeletePreferenceAsync(UserPreference preference)
    {
        _context.UserPreferences.Remove(preference);
        return Task.CompletedTask;
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        return await _context.Users
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
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u =>
                u.Email == normalizedIdentifier || u.Username == normalizedIdentifier);
    }

    public async Task<bool> EmailExistsAsync(string email)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();

        return await _context.Users
            .AsNoTracking()
            .AnyAsync(u => u.Email == normalizedEmail);
    }

    public async Task<bool> UsernameExistsAsync(string username)
    {
        var normalizedUsername = username.Trim().ToLowerInvariant();

        return await _context.Users
            .AsNoTracking()
            .AnyAsync(u => u.Username == normalizedUsername);
    }

    public async Task<User> CreateAsync(User user, Person person)
    {
        await _context.People.AddAsync(person);
        user.Person = person;
        await _context.Users.AddAsync(user);
        return user;
    }

    public Task UpdateAsync(User user)
    {
        _context.Users.Update(user);
        return Task.CompletedTask;
    }

    public async Task SoftDeleteAsync(int userId)
    {
        var user = await _context.Users
            .Include(u => u.Person)
            .FirstOrDefaultAsync(u => u.PersonId == userId);

        if (user is null)
            return;

        user.SoftDelete();
    }

    public async Task<PagedResult<User>> GetAllAsync(UserFilterDto filter)
    {
        filter ??= new UserFilterDto();
        ValidatePaging(filter.Page, filter.PageSize, MaxPageSize);

        var query = _context.Users
            .AsNoTracking()
            .Include(u => u.Person)
            .Where(u => u.Person != null && !u.Person.IsDeleted)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var term = filter.Search.Trim().ToLower();

            query = query.Where(u =>
                u.Username.Contains(term, StringComparison.CurrentCultureIgnoreCase) ||
                u.Email.ToLower().Contains(term) ||
                u.Person!.FirstName.Contains(term, StringComparison.CurrentCultureIgnoreCase) ||
                u.Person.LastName.Contains(term, StringComparison.CurrentCultureIgnoreCase) ||
                ((u.Person.FirstName + " " + u.Person.LastName).Contains(term, StringComparison.CurrentCultureIgnoreCase)) ||
                ((u.Person.PhoneNumber ?? string.Empty).Contains(term, StringComparison.CurrentCultureIgnoreCase)));
        }

        if (!string.IsNullOrWhiteSpace(filter.Role) &&
            Enum.TryParse<UserRole>(filter.Role, true, out var parsedRole))
        {
            query = query.Where(u => u.Role == parsedRole);
        }

        if (filter.IsBanned.HasValue)
            query = query.Where(u => u.IsBanned == filter.IsBanned.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .ThenBy(u => u.PersonId)
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
            .Include(r => r.User)
            .ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r =>
                r.TokenHash == tokenHash &&
                r.RevokedAt == null &&
                r.ExpiresAt > DateTime.UtcNow);

    public async Task<RefreshToken?> GetRefreshTokenAsync(string tokenHash) =>
        await _context.RefreshTokens
            .Include(r => r.User)
            .ThenInclude(u => u!.Person)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash);

    public Task AddRefreshTokenAsync(RefreshToken token)
    {
        _context.RefreshTokens.Add(token);
        return Task.CompletedTask;
    }

    public async Task RevokeRefreshTokenAsync(string tokenHash)
    {
        var token = await _context.RefreshTokens
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash);

        if (token is null)
            return;

        token.Revoke();
    }

    public Task RevokeAllUserTokensAsync(int userId) =>
        _context.RefreshTokens
            .Where(r => r.UserId == userId && r.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(r => r.RevokedAt, DateTime.UtcNow));

    public Task CleanupExpiredTokensAsync(int userId) =>
        _context.RefreshTokens
            .Where(r => r.UserId == userId && r.ExpiresAt <= DateTime.UtcNow)
            .ExecuteDeleteAsync();

    public async Task<PasswordResetToken?> GetActivePasswordResetTokenAsync(int userId, string tokenHash) =>
        await _context.PasswordResetTokens
            .FirstOrDefaultAsync(x =>
                x.UserId == userId &&
                x.TokenHash == tokenHash &&
                x.UsedAt == null &&
                x.ExpiresAt > DateTime.UtcNow);

    public async Task InvalidateActivePasswordResetTokensAsync(int userId)
    {
        var activeTokens = await _context.PasswordResetTokens
            .Where(x => x.UserId == userId && x.UsedAt == null && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync();

        foreach (var token in activeTokens)
        {
            token.Invalidate();
        }
    }

    public Task CreatePasswordResetTokenAsync(PasswordResetToken token)
    {
        _context.PasswordResetTokens.Add(token);
        return Task.CompletedTask;
    }

    public Task MarkPasswordResetTokenUsedAsync(PasswordResetToken token)
    {
        _context.PasswordResetTokens.Update(token);
        return Task.CompletedTask;
    }
}