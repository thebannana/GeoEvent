namespace EventService.Application.Interfaces.Services;

public interface IImageStorageService
{
    Task<string> UploadImageAsync(
        Stream stream,
        string fileName,
        string contentType,
        string folder,
        CancellationToken cancellationToken = default);
}