using System.Net;
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
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (ReportNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (UserBannedException ex)
        {
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (UserLockedOutException ex)
        {
            await Write(context, StatusCodes.Status423Locked, ex.Message);
        }
        catch (EmailNotVerifiedException ex)
        {
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (EmailAlreadyTakenException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (UsernameTakenException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (InvalidRefreshTokenException ex)
        {
            await Write(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);
            await Write(context, StatusCodes.Status500InternalServerError,
                "An unexpected error occurred.");
        }
    }

    private static Task Write(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        var body = JsonSerializer.Serialize(new { error = message });
        return context.Response.WriteAsync(body);
    }
}