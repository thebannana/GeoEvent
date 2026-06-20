using System.Security.Claims;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Http;

namespace EventService.Infrastructure.Services;

public sealed class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int GetRequiredUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User
            ?? throw new UnauthorizedAccessException("User context is not available.");

        var claimValue = user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID claim not found.");

        if (!int.TryParse(claimValue, out var userId) || userId <= 0)
            throw new UnauthorizedAccessException("Invalid user ID claim.");

        return userId;
    }

    public int? GetUserIdOrNull()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated != true)
            return null;

        var claimValue = user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub");

        return int.TryParse(claimValue, out var userId) && userId > 0
            ? userId
            : null;
    }

    public string GetRequiredRole()
    {
        var user = _httpContextAccessor.HttpContext?.User
            ?? throw new UnauthorizedAccessException("User context is not available.");

        return user.FindFirstValue(ClaimTypes.Role)
            ?? throw new UnauthorizedAccessException("Role claim not found.");
    }

    public bool IsInRole(string role)
    {
        var user = _httpContextAccessor.HttpContext?.User;
        return user?.IsInRole(role) == true;
    }
}