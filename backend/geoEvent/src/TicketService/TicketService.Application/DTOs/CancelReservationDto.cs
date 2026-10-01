namespace TicketService.Application.DTOs;

public class CancelReservationDto
{
    /// <summary>
    /// Human-readable cancellation reason provided by the user.
    /// Required for user-initiated cancellations via the UI.
    /// System-initiated paths (e.g. PayPal abort) supply a fixed system reason.
    /// </summary>
    public string? Reason { get; set; }
}
