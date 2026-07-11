using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using UserService.API.Extensions;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Services;

namespace UserService.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var result = await _authService.ForgotPasswordAsync(dto);

        return result.Success
            ? Ok(new { message = "If the account exists, a password reset email has been sent." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        if (dto is null)
            return BadRequest(new { error = "Request body is required." });

        var result = await _authService.ResetPasswordAsync(dto);

        return result.Success
            ? Ok(new { message = "Password has been reset successfully." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto request)
    {
        if (request is null)
            return BadRequest(new { error = "Request body is required." });

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var result = await _authService.RegisterAsync(request, ipAddress);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        if (request is null)
            return BadRequest(new { error = "Request body is required." });

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var result = await _authService.LoginAsync(request, ipAddress);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("refresh")]
    [EnableRateLimiting("auth")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto request)
    {
        if (request is null)
            return BadRequest(new { error = "Request body is required." });

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var result = await _authService.RefreshTokenAsync(request.RefreshToken, ipAddress);

        return result.Success
            ? Ok(result.Data)
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] RefreshTokenRequestDto request)
    {
        if (request is null)
            return BadRequest(new { error = "Request body is required." });

        var result = await _authService.LogoutAsync(request.RefreshToken);

        return result.Success
            ? Ok(new { message = "Logged out successfully." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }

    [HttpPost("revoke-all")]
    [Authorize]
    public async Task<IActionResult> RevokeAllSessions()
    {
        var userId = User.GetUserId();
        var result = await _authService.RevokeAllSessionsAsync(userId);

        return result.Success
            ? Ok(new { message = "All sessions revoked successfully." })
            : StatusCode(result.StatusCode, new { error = result.Error });
    }
}