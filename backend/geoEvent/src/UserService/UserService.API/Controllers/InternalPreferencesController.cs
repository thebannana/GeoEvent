using Microsoft.AspNetCore.Mvc;
using UserService.API.Filters;
using UserService.Application.DTOs;
using UserService.Application.DTOs.Internal;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/internal/preferences")]
[ServiceFilter(typeof(InternalApiKeyAuthFilter))]
public sealed class InternalPreferencesController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<InternalPreferencesController> _logger;

    public InternalPreferencesController(
        IUserService userService,
        ILogger<InternalPreferencesController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    [HttpPost("interactions")]
    public async Task<IActionResult> ApplyInteractionPreference(
        [FromBody] ApplyUserEventPreferenceInteractionRequest request)
    {
        if (request.UserId <= 0)
            return BadRequest(new { error = "UserId is required." });

        if (request.EventId <= 0)
            return BadRequest(new { error = "EventId is required." });

        if (string.IsNullOrWhiteSpace(request.InteractionType))
            return BadRequest(new { error = "InteractionType is required." });

        await _userService.ApplyInteractionPreferenceAsync(
            request.UserId,
            request.EventId,
            request.SegmentId,
            request.GenreId,
            request.SubGenreId,
            request.InteractionType.Trim(),
            request.OccurredAt);

        _logger.LogInformation(
            "Applied interaction preference for UserId {UserId}, EventId {EventId}, InteractionType {InteractionType}",
            request.UserId,
            request.EventId,
            request.InteractionType);

        return Ok(new
        {
            message = "Interaction preference applied successfully."
        });
    }

    [HttpGet("users/{userId:int}")]
    public async Task<IActionResult> GetByUserId(int userId)
    {
        if (userId <= 0)
            return BadRequest(new { error = "A valid user ID must be provided." });

        var filter = new PreferencesFilterDto
        {
            Page = 1,
            PageSize = 100
        };

        var result = await _userService.GetUserPreferencesAsync(userId, filter);

        return result.Success
            ? Ok(result.Data?.Items ?? [])
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}