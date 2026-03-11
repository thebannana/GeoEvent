namespace TicketService.Domain.Exceptions;

public class ReservationAlreadyConfirmedException : Exception
{
    public ReservationAlreadyConfirmedException(int reservationId)
        : base($"Reservation {reservationId} has already been confirmed.") { }
}