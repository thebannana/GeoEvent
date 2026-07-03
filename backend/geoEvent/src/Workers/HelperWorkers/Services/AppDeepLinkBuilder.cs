using System.Net;

namespace GeoEvent.HelperWorkers.Services;

public static class AppDeepLinkBuilder
{
    public static string BuildResetPasswordLink(string email, string token)
    {
        var encodedEmail = WebUtility.UrlEncode(email);
        var encodedToken = WebUtility.UrlEncode(token);

        return $"geoevent://open/reset-password?email={encodedEmail}&token={encodedToken}";
    }
}