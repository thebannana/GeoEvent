using EventService.Application.DTOs;

namespace EventService.Application.Interfaces.Services;

public interface IUserProfileService
{
    Task<IReadOnlyDictionary<int, CommentUserProfileDto>> GetProfilesByIdsAsync(IEnumerable<int> userIds);
    Task<IReadOnlyList<UserPreferenceDto>> GetUserPreferencesAsync(int userId);
}