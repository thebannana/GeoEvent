namespace EventService.API.Security;

public static class AppRoles
{
    public const string Admin = "Admin";
    public const string User = "User";

    public const string AdminOrUser = $"{Admin},{User}";
}