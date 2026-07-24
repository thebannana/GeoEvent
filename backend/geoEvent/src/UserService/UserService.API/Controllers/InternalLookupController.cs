using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/internal/lookup")]
[Authorize]
public class InternalLookupController : ControllerBase
{
    private readonly IUserService userService;

    public InternalLookupController(IUserService userService)
    {
        this.userService = userService;
    }

    [HttpGet("reviews/{reviewId:int}")]
    public async Task<IActionResult> GetReview(int reviewId)
    {
        var result = await userService.GetInternalReviewLookupAsync(reviewId);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}