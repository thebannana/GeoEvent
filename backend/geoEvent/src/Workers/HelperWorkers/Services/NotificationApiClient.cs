using System.Net.Http.Json;
using GeoEvent.HelperWorkers.DTOs;
using GeoEvent.HelperWorkers.Interfaces;
using GeoEvent.HelperWorkers.Options;
using Microsoft.Extensions.Options;

namespace GeoEvent.HelperWorkers.Services;

public class NotificationApiClient : INotificationApiClient
{
    private readonly HttpClient _httpClient;
    private readonly NotificationServiceOptions _options;

    public NotificationApiClient(
        HttpClient httpClient,
        IOptions<NotificationServiceOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public async Task CreateNotificationAsync(
        CreateNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        using var message = new HttpRequestMessage(
            HttpMethod.Post,
            "/api/internal/notifications")
        {
            Content = JsonContent.Create(request)
        };

        message.Headers.Add("X-Api-Key", _options.InternalApiKey);

        using var response = await _httpClient.SendAsync(message, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpRequestException(
                $"NotificationService internal API call failed: {(int)response.StatusCode} {response.ReasonPhrase}. Body: {body}");
        }
    }
}