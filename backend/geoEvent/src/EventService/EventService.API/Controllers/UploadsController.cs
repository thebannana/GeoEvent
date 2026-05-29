using EventService.Application.DTOs;
using EventService.Application.Interfaces.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace EventService.API.Controllers;

[ApiController]
[Route("api/uploads")]
[Authorize(Roles = "User,Organizer,Admin")]
public class UploadsController : ControllerBase
{
    private readonly IImageStorageService imageStorageService;

    public UploadsController(IImageStorageService imageStorageService)
    {
        this.imageStorageService = imageStorageService;
    }

    [HttpPost("images")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10_000_000)]
    public async Task<IActionResult> UploadImage(
        [FromForm] IFormFile file,
        CancellationToken cancellationToken)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { error = "No file was uploaded." });
        }

        var allowedTypes = new[]
        {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp"
        };

        if (!allowedTypes.Contains(file.ContentType?.ToLowerInvariant()))
        {
            return BadRequest(new { error = "Only JPG, PNG, and WEBP images are allowed." });
        }

        if (file.Length > 10_000_000)
        {
            return BadRequest(new { error = "Image must be smaller than 10 MB." });
        }

        await using var stream = file.OpenReadStream();

        var imageUrl = await imageStorageService.UploadImageAsync(
            stream,
            file.FileName,
            file.ContentType ?? "application/octet-stream",
            "events",
            cancellationToken);

        return Ok(new ImageUploadResponseDto
        {
            ImageUrl = imageUrl
        });
    }
}