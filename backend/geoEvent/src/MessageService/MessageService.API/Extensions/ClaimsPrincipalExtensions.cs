using System.Security.Claims;

namespace MessageService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)
            ?? user.FindFirst("sub")
            ?? throw new UnauthorizedAccessException("User ID claim not found.");

        if (!int.TryParse(claim.Value, out var userId))
            throw new UnauthorizedAccessException("Invalid user ID claim.");

        return userId;
    }
}