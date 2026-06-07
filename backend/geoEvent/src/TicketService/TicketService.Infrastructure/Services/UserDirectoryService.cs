using System.Net.Http.Json;
public class UserDirectoryService : IUserDirectoryService
{
    private readonly HttpClient _httpClient;

    public UserDirectoryService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<List<PublicUserProfileDto>> GetPublicProfilesAsync(IEnumerable<int> userIds)
    {
        var ids = userIds?
            .Where(x => x > 0)
            .Distinct()
            .ToList() ?? new List<int>();

        if (ids.Count == 0)
            return new List<PublicUserProfileDto>();

        var query = string.Join("&", ids.Select(id => $"ids={id}"));
        var response = await _httpClient.GetAsync($"api/users/public?{query}");

        if (!response.IsSuccessStatusCode)
            return new List<PublicUserProfileDto>();

        var data = await response.Content.ReadFromJsonAsync<List<PublicUserProfileDto>>();
        return data ?? new List<PublicUserProfileDto>();
    }
}