using System.Text.Json;
using NotificationService.Domain.Exceptions;

namespace NotificationService.API.Middleware;

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
        catch (NotificationNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (NotificationQueueNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (NotificationAccessDeniedException ex)
        {
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (NotificationAlreadyReadException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (QueueItemCannotBeRetriedException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (QueueItemCannotBeCancelledException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
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
        return context.Response.WriteAsync(
            JsonSerializer.Serialize(new { error = message }));
    }
}
