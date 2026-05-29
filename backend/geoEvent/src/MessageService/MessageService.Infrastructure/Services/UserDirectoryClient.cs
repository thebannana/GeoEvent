using System.Text.Json;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Services;

namespace MessageService.Infrastructure.Services;

public class UserDirectoryClient : IUserDirectoryClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public UserDirectoryClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PublicUserSummaryDto?> GetPublicUserAsync(int userId, CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"/api/users/{userId}/public", cancellationToken);
        if (!response.IsSuccessStatusCode) return null;

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        return await JsonSerializer.DeserializeAsync<PublicUserSummaryDto>(stream, JsonOptions, cancellationToken);
    }

    public async Task<Dictionary<int, PublicUserSummaryDto>> GetPublicUsersAsync(IEnumerable<int> userIds, CancellationToken cancellationToken = default)
    {
        var ids = userIds.Distinct().ToList();
        if (ids.Count == 0) return new Dictionary<int, PublicUserSummaryDto>();

        var query = string.Join("&", ids.Select(id => $"ids={id}"));
        var response = await _httpClient.GetAsync($"/api/users/public?{query}", cancellationToken);
        if (!response.IsSuccessStatusCode) return new Dictionary<int, PublicUserSummaryDto>();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        var users = await JsonSerializer.DeserializeAsync<List<PublicUserSummaryDto>>(stream, JsonOptions, cancellationToken)
                   ?? new List<PublicUserSummaryDto>();

        return users.ToDictionary(x => x.UserId, x => x);
    }
}