using System.Net.Http.Headers;
using EventService.Application.Common.Settings;
using EventService.Application.Interfaces.Services;
using Microsoft.Extensions.Options;

namespace EventService.Infrastructure.Services;

public class SupabaseImageStorageService : IImageStorageService
{
    private static readonly HashSet<string> AllowedExtensions =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        };

    private readonly HttpClient _httpClient;
    private readonly SupabaseStorageSettings _settings;

    public SupabaseImageStorageService(
        HttpClient httpClient,
        IOptions<SupabaseStorageSettings> options)
    {
        _httpClient = httpClient;
        _settings = options.Value;

        if (string.IsNullOrWhiteSpace(_settings.Url) ||
            string.IsNullOrWhiteSpace(_settings.ServiceRoleKey) ||
            string.IsNullOrWhiteSpace(_settings.Bucket))
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
        if (stream is null)
            throw new InvalidOperationException("Image stream is missing.");

        if (string.IsNullOrWhiteSpace(fileName))
            throw new InvalidOperationException("File name is required.");

        if (string.IsNullOrWhiteSpace(folder))
            throw new InvalidOperationException("Folder is required.");

        if (string.IsNullOrWhiteSpace(contentType) ||
            !contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Only image files are allowed.");
        }

        var extension = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.Contains(extension))
        {
            throw new InvalidOperationException("Only JPG, PNG, and WEBP images are allowed.");
        }

        var safeName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var objectPath = $"{folder.Trim('/')}/{safeName}";

        using var content = new StreamContent(stream);
        content.Headers.ContentType = new MediaTypeHeaderValue(contentType);

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{_settings.Url.TrimEnd('/')}/storage/v1/object/{_settings.Bucket}/{objectPath}");

        request.Headers.Add("apikey", _settings.ServiceRoleKey);
        request.Headers.Authorization =
            new AuthenticationHeaderValue("Bearer", _settings.ServiceRoleKey);
        request.Headers.Add("x-upsert", "false");
        request.Content = content;

        var response = await _httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Supabase upload failed with status {(int)response.StatusCode} ({response.ReasonPhrase}).");
        }

        return $"{_settings.Url.TrimEnd('/')}/storage/v1/object/public/{_settings.Bucket}/{objectPath}";
    }
}