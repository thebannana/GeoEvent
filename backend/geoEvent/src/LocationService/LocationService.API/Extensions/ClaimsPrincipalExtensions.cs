using System.Security.Claims;

namespace LocationService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)
            ?? user.FindFirst("sub")
            ?? throw new UnauthorizedAccessException("User ID claim not found.");
        return int.Parse(claim.Value);
    }

    public static string GetRole(this ClaimsPrincipal user) =>
    user.FindFirstValue(ClaimTypes.Role)
        ?? throw new UnauthorizedAccessException("Role claim not found.");

}
