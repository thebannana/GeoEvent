namespace TicketService.Domain.Exceptions;

public class TicketNotFoundException : Exception
{
    public TicketNotFoundException(int ticketId)
        : base($"Ticket with ID {ticketId} was not found.") { }
}
