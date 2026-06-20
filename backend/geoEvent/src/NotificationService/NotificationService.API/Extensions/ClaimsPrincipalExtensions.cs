using System.Security.Claims;

namespace NotificationService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(value))
            throw new UnauthorizedAccessException("User ID claim not found.");

        if (!int.TryParse(value, out var userId))
            throw new UnauthorizedAccessException("User ID claim is invalid.");

        return userId;
    }

    public static string GetRole(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.Role);

        if (string.IsNullOrWhiteSpace(value))
            throw new UnauthorizedAccessException("Role claim not found.");

        return value;
    }
}