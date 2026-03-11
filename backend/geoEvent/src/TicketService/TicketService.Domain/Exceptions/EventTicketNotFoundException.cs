namespace TicketService.Domain.Exceptions;

public class EventTicketNotFoundException : Exception
{
    public EventTicketNotFoundException(int ticketId)
        : base($"Event ticket with ID {ticketId} was not found.") { }
}