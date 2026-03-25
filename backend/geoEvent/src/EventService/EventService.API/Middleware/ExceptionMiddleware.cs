using System.Text.Json;
using EventService.Domain.Exceptions;

namespace EventService.API.Middleware;

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
        catch (EventNotFoundException ex) { await Write(context, 404, ex.Message); }
        catch (VenueNotFoundException ex) { await Write(context, 404, ex.Message); }
        catch (CommentNotFoundException ex) { await Write(context, 404, ex.Message); }
        catch (BookmarkNotFoundException ex) { await Write(context, 404, ex.Message); }
        catch (InvalidOperationException ex) { await Write(context, 400, ex.Message); }
        catch (EventAccessDeniedException ex) { await Write(context, 403, ex.Message); }
        catch (CommentAccessDeniedException ex) { await Write(context, 403, ex.Message); }
        catch (DuplicateLikeException ex) { await Write(context, 400, ex.Message); }
        catch (DuplicateBookmarkException ex) { await Write(context, 409, ex.Message); }
        catch (EventCapacityExceededException ex) { await Write(context, 409, ex.Message); }
        catch (EventNotActiveException ex) { await Write(context, 422, ex.Message); }
        catch (UnauthorizedAccessException ex) { await Write(context, 401, ex.Message); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);
            await Write(context, 500, "An unexpected error occurred.");
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
