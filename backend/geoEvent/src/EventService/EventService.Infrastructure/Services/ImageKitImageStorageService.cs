using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using EventService.Application.Common.Settings;
using EventService.Application.Interfaces.Services;
using Microsoft.Extensions.Options;

namespace EventService.Infrastructure.Services;

public class ImageKitImageStorageService : IImageStorageService
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
    private readonly ImageKitSettings _settings;

    public ImageKitImageStorageService(
        HttpClient httpClient,
        IOptions<ImageKitSettings> options)
    {
        _httpClient = httpClient;
        _settings = options.Value;

        if (string.IsNullOrWhiteSpace(_settings.PrivateKey) ||
            string.IsNullOrWhiteSpace(_settings.UrlEndpoint))
        {
            throw new InvalidOperationException("ImageKit configuration is missing.");
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

        using var memoryStream = new MemoryStream();
        await stream.CopyToAsync(memoryStream, cancellationToken);
        var bytes = memoryStream.ToArray();

        var safeName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var normalizedFolder = "/" + folder.Trim('/');

        using var form = new MultipartFormDataContent();

        var fileContent = new StringContent(Convert.ToBase64String(bytes));
        form.Add(fileContent, "file");
        form.Add(new StringContent(safeName), "fileName");
        form.Add(new StringContent(normalizedFolder), "folder");
        form.Add(new StringContent("true"), "useUniqueFileName");
        form.Add(new StringContent("false"), "overwrite");
        form.Add(new StringContent("false"), "isPrivateFile");

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            "https://upload.imagekit.io/api/v1/files/upload");

        var basicToken = Convert.ToBase64String(
            Encoding.ASCII.GetBytes($"{_settings.PrivateKey}:"));
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", basicToken);
        request.Content = form;

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"ImageKit upload failed with status {(int)response.StatusCode} ({response.ReasonPhrase}). Response: {responseBody}");
        }

        using var document = JsonDocument.Parse(responseBody);

        if (!document.RootElement.TryGetProperty("url", out var urlElement))
        {
            throw new InvalidOperationException("ImageKit upload succeeded but no URL was returned.");
        }

        var url = urlElement.GetString();
        if (string.IsNullOrWhiteSpace(url))
        {
            throw new InvalidOperationException("ImageKit returned an empty file URL.");
        }

        return url;
    }
}