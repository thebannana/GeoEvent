using TicketService.Application.Common;
using TicketService.Domain.Entities;

namespace TicketService.Application.Interfaces.Repositories;

public interface ITicketRepository
{
    // Reservations
    Task<Reservation?> GetReservationByIdAsync(int reservationId);
    Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, int page, int pageSize);
    Task<Reservation> CreateReservationAsync(Reservation reservation);
    Task UpdateReservationAsync(Reservation reservation);
    Task<List<Reservation>> GetExpiredReservationsAsync();

    // Event tickets (ticket types per event)
    Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId);
    Task<EventTicket?> GetEventTicketByEventAndTypeAsync(int eventId, string ticketType);

    // Issued tickets
    Task<Ticket?> GetTicketByIdAsync(int ticketId);
    Task<Ticket?> GetTicketByQrCodeAsync(string qrCode);
    Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId);
    Task<List<Ticket>> GetUserTicketsAsync(int userId);
    Task<List<Ticket>> GetEventTicketsAsync(int eventId);
    Task AddTicketsAsync(IEnumerable<Ticket> tickets);
    Task UpdateTicketAsync(Ticket ticket);

    // Payments
    Task AddPaymentDetailAsync(PaymentDetail payment);
}
