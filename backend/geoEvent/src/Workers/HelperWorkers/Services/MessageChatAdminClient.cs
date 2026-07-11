using System.Net.Http.Json;
using GeoEvent.HelperWorkers.Interfaces;

namespace GeoEvent.HelperWorkers.Services;

public sealed class MessageChatAdminClient : IMessageChatAdminClient
{
    private readonly HttpClient _httpClient;

    public MessageChatAdminClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task AddUserToEventThreadAsync(int eventId, int userId, int? addedByUserId = null)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            "/api/internal/chat/event-thread/add-user",
            new
            {
                eventId,
                userId,
                addedByUserId
            });

        response.EnsureSuccessStatusCode();
    }

    public async Task RemoveUserFromEventThreadAsync(int eventId, int userId)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            "/api/internal/chat/event-thread/remove-user",
            new
            {
                eventId,
                userId
            });

        response.EnsureSuccessStatusCode();
    }

    public async Task HandleDeletedUserAsync(int userId)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            "/api/internal/chat/users/handle-deleted",
            new
            {
                userId
            });

        response.EnsureSuccessStatusCode();
    }
}