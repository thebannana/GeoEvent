using System.Security.Claims;

namespace EventService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)
            ?? user.FindFirst("sub")
            ?? throw new UnauthorizedAccessException("User ID claim not found.");

        return int.TryParse(claim.Value, out var userId) && userId > 0
            ? userId
            : throw new UnauthorizedAccessException("Invalid user ID claim.");
    }

    public static string GetRole(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Role)
            ?? throw new UnauthorizedAccessException("Role claim not found.");
}