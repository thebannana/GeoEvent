using System.Security.Claims;

namespace TicketService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!int.TryParse(value, out var userId))
            throw new UnauthorizedAccessException("User ID claim is missing or invalid.");

        return userId;
    }

    public static string GetRole(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Role)
            ?? throw new UnauthorizedAccessException("Role claim not found.");
}
