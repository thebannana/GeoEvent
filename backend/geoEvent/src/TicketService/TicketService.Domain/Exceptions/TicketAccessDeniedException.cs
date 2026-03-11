namespace TicketService.Domain.Exceptions;

public class TicketAccessDeniedException : Exception
{
    public TicketAccessDeniedException()
        : base("You do not have access to this ticket.") { }
}