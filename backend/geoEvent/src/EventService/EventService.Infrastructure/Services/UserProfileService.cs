using System.Net.Http.Json;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.Extensions.Logging;

namespace EventService.Infrastructure.Services;

public class UserProfileService : IUserProfileService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<UserProfileService> _logger;

    public UserProfileService(HttpClient httpClient, ILogger<UserProfileService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<
        IReadOnlyList<UserPreferenceDto>
    > GetUserPreferencesAsync(int userId)
    {
        if (userId <= 0)
        {
            return Array.Empty<UserPreferenceDto>();
        }

        try
        {
            var response = await _httpClient.GetAsync(
                $"api/internal/preferences/users/{userId}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Failed to fetch user preferences. " +
                    "StatusCode: {StatusCode}, UserId: {UserId}",
                    response.StatusCode,
                    userId);

                return Array.Empty<UserPreferenceDto>();
            }

            var data = await response.Content
                .ReadFromJsonAsync<List<UserPreferenceDto>>();

            return data ??
                new List<UserPreferenceDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Error while fetching user preferences " +
                "for user {UserId}.",
                userId);

            return Array.Empty<UserPreferenceDto>();
        }
    }

    public async Task<IReadOnlyDictionary<int, CommentUserProfileDto>> GetProfilesByIdsAsync(IEnumerable<int> userIds)
    {
        var ids = userIds.Where(id => id > 0).Distinct().ToList();

        if (ids.Count == 0)
            return new Dictionary<int, CommentUserProfileDto>();

        try
        {
            var query = string.Join("&", ids.Select(id => $"ids={id}"));
            var url = $"api/users/profiles?{query}";

            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Failed to fetch user profiles. StatusCode: {StatusCode}, Url: {Url}",
                    response.StatusCode,
                    url);

                return BuildFallback(ids);
            }

            var profiles = await response.Content.ReadFromJsonAsync<List<CommentUserProfileDto>>();

            if (profiles is null || profiles.Count == 0)
                return BuildFallback(ids);

            var map = profiles
                .GroupBy(x => x.UserId)
                .ToDictionary(g => g.Key, g => g.First());

            foreach (var id in ids)
            {
                if (!map.ContainsKey(id))
                    map[id] = BuildFallbackProfile(id);
            }

            return map;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while fetching user profiles.");
            return BuildFallback(ids);
        }
    }

    private static Dictionary<int, CommentUserProfileDto> BuildFallback(IEnumerable<int> ids)
    {
        return ids
            .Distinct()
            .ToDictionary(id => id, BuildFallbackProfile);
    }

    private static CommentUserProfileDto BuildFallbackProfile(int userId)
    {
        return new CommentUserProfileDto
        {
            UserId = userId,
            Username = $"user{userId}",
            DisplayName = $"User {userId}",
            AvatarUrl = null
        };
    }
}