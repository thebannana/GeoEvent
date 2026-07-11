using System.Text.Json;
using UserService.Domain.Exceptions;

namespace UserService.API.Middleware;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (UserNotFoundException ex)
        {
            _logger.LogWarning(ex, "User not found.");
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (ReportNotFoundException ex)
        {
            _logger.LogWarning(ex, "Report not found.");
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (UserBannedException ex)
        {
            _logger.LogWarning(ex, "Banned user attempted a forbidden action.");
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (UserLockedOutException ex)
        {
            _logger.LogWarning(ex, "Locked out user attempted access.");
            await Write(context, StatusCodes.Status423Locked, ex.Message);
        }
        catch (EmailAlreadyTakenException ex)
        {
            _logger.LogWarning(ex, "Email conflict.");
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (UsernameTakenException ex)
        {
            _logger.LogWarning(ex, "Username conflict.");
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (InvalidRefreshTokenException ex)
        {
            _logger.LogWarning(ex, "Invalid refresh token.");
            await Write(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access.");
            await Write(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception.");
            await Write(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
        }
    }

    private static Task Write(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";

        var body = JsonSerializer.Serialize(new
        {
            error = message
        });

        return context.Response.WriteAsync(body);
    }
}