using System.Text.Json;
using TicketService.Domain.Exceptions;

namespace TicketService.API.Middleware;

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
        catch (ReservationNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (TicketNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (EventTicketNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (PaymentNotFoundException ex)
        {
            await Write(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (ReservationAccessDeniedException ex)
        {
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (TicketAccessDeniedException ex)
        {
            await Write(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (TicketNotAvailableException ex)
        {
            await Write(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (ReservationAlreadyConfirmedException ex)
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
