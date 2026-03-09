namespace TicketService.Domain.Exceptions;

public class ReservationNotFoundException : Exception
{
    public ReservationNotFoundException(int reservationId)
        : base($"Reservation with ID {reservationId} was not found.") { }
}
