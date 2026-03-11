namespace TicketService.Domain.Exceptions;

public class ReservationAccessDeniedException : Exception
{
    public ReservationAccessDeniedException()
        : base("You do not have access to this reservation.") { }
}