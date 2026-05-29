using System.Net.Http.Headers;
using EventService.Application.Common.Settings;
using EventService.Application.Interfaces.Services;
using Microsoft.Extensions.Options;

namespace EventService.Infrastructure.Services;

public class SupabaseImageStorageService : IImageStorageService
{
    private readonly HttpClient httpClient;
    private readonly SupabaseStorageSettings settings;

    public SupabaseImageStorageService(
        HttpClient httpClient,
        IOptions<SupabaseStorageSettings> options)
    {
        this.httpClient = httpClient;
        settings = options.Value;

        if (string.IsNullOrWhiteSpace(settings.Url) ||
            string.IsNullOrWhiteSpace(settings.ServiceRoleKey) ||
            string.IsNullOrWhiteSpace(settings.Bucket))
        {
            throw new InvalidOperationException("Supabase Storage configuration is missing.");
        }
    }

    public async Task<string> UploadImageAsync(
        Stream stream,
        string fileName,
        string contentType,
        string folder,
        CancellationToken cancellationToken = default)
    {
        if (stream == null)
            throw new InvalidOperationException("Image stream is missing.");

        if (string.IsNullOrWhiteSpace(contentType) ||
            !contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Only image files are allowed.");
        }

        var extension = Path.GetExtension(fileName);
        var safeName = $"{Guid.NewGuid()}{extension}";
        var objectPath = $"{folder.Trim('/')}/{safeName}";

        using var content = new StreamContent(stream);
        content.Headers.ContentType = new MediaTypeHeaderValue(contentType);

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{settings.Url.TrimEnd('/')}/storage/v1/object/{settings.Bucket}/{objectPath}");

        request.Headers.Add("apikey", settings.ServiceRoleKey);
        request.Headers.Authorization =
            new AuthenticationHeaderValue("Bearer", settings.ServiceRoleKey);
        request.Headers.Add("x-upsert", "false");
        request.Content = content;

        var response = await httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Supabase upload failed: {(int)response.StatusCode} {response.ReasonPhrase}. {responseBody}");
        }

        return $"{settings.Url.TrimEnd('/')}/storage/v1/object/public/{settings.Bucket}/{objectPath}";
    }
}