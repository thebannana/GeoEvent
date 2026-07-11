using System.Security.Claims;

namespace MessageService.API.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        var userId = user.GetUserIdOrNull();
        return userId ?? throw new UnauthorizedAccessException("User ID claim not found.");
    }

    public static int? GetUserIdOrNull(this ClaimsPrincipal? user)
    {
        if (user is null)
            return null;

        var claim = user.FindFirst(ClaimTypes.NameIdentifier)
            ?? user.FindFirst("sub");

        if (claim is null)
            return null;

        return int.TryParse(claim.Value, out var userId) ? userId : null;
    }
}