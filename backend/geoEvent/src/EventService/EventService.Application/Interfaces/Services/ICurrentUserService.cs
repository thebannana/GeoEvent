namespace EventService.Application.Interfaces.Services;

public interface ICurrentUserService
{
    int GetRequiredUserId();
    int? GetUserIdOrNull();
    string GetRequiredRole();
    bool IsInRole(string role);
}