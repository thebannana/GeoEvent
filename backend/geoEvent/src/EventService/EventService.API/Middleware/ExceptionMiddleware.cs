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
        catch (Exception ex) when (ex is
            EventNotFoundException or
            CommentNotFoundException or
            BookmarkNotFoundException or
            GenreNotFoundException or
            SegmentNotFoundException or
            SubGenreNotFoundException)
        {
            await WriteAsync(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (Exception ex) when (ex is
            EventAccessDeniedException or
            CommentAccessDeniedException)
        {
            await WriteAsync(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (Exception ex) when (ex is
            DuplicateLikeException or
            DuplicateBookmarkException or
            DuplicateCommentLikeException or
            EventCapacityExceededException)
        {
            await WriteAsync(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (Exception ex) when (ex is
            InvalidOperationException or
            InvalidBookmarkException or
            InvalidCommentException or
            InvalidCommentLikeException or
            InvalidEventDataException or
            InvalidEventImageException or
            InvalidEventLikeException or
            InvalidEventStateException or
            InvalidEventStateTransitionException or
            InvalidReferenceDataException or
            CommentAlreadyDeletedException)
        {
            await WriteAsync(context, StatusCodes.Status400BadRequest, ex.Message);
        }
        catch (EventNotActiveException ex)
        {
            await WriteAsync(context, StatusCodes.Status422UnprocessableEntity, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            await WriteAsync(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);
            await WriteAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
        }
    }

    private static Task WriteAsync(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";

        return context.Response.WriteAsync(
            JsonSerializer.Serialize(new
            {
                error = message
            }));
    }
}