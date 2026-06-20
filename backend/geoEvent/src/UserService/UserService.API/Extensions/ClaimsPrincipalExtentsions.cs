using System.Security.Claims;

namespace UserService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrWhiteSpace(value))
            throw new UnauthorizedAccessException("User ID claim not found.");

        if (!int.TryParse(value, out var userId))
            throw new UnauthorizedAccessException("Invalid user ID claim.");

        return userId;
    }

    public static string GetEmail(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Email)
            ?? throw new UnauthorizedAccessException("Email claim not found.");

    public static string GetRole(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Role)
            ?? throw new UnauthorizedAccessException("Role claim not found.");
}