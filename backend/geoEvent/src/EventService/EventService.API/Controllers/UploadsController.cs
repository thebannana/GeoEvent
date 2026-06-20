using EventService.API.Security;
using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/uploads")]
[Authorize(Roles = AppRoles.AdminOrUser)]
public class UploadsController : ControllerBase
{
    private readonly IImageStorageService _imageStorageService;
    private readonly ICurrentUserService _currentUserService;

    public UploadsController(
        IImageStorageService imageStorageService,
        ICurrentUserService currentUserService)
    {
        _imageStorageService = imageStorageService;
        _currentUserService = currentUserService;
    }

    [HttpPost("images")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10_000_000)]
    public async Task<IActionResult> UploadImage(
        [FromForm] IFormFile file,
        CancellationToken cancellationToken)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new { error = "No file was uploaded." });

        if (file.Length > 10_000_000)
            return BadRequest(new { error = "Image must be smaller than 10 MB." });

        var allowedTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/png",
            "image/webp"
        };

        if (string.IsNullOrWhiteSpace(file.ContentType) || !allowedTypes.Contains(file.ContentType))
            return BadRequest(new { error = "Only JPG, PNG, and WEBP images are allowed." });

        await using var stream = file.OpenReadStream();

        var isValidSignature = await FileSignatureValidator.IsSupportedImageAsync(stream, cancellationToken);
        if (!isValidSignature)
            return BadRequest(new { error = "Uploaded file content is not a valid JPG, PNG, or WEBP image." });

        var userId = _currentUserService.GetRequiredUserId();

        var imageUrl = await _imageStorageService.UploadImageAsync(
            stream,
            file.FileName,
            file.ContentType,
            $"profiles/{userId}",
            cancellationToken);

        return Ok(new ImageUploadResponseDto
        {
            ImageUrl = imageUrl
        });
    }
}