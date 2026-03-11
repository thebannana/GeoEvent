namespace TicketService.Domain.Exceptions;

public class TicketNotAvailableException : Exception
{
    public TicketNotAvailableException(int ticketId)
        : base($"Event ticket {ticketId} is not available for purchase.") { }
}