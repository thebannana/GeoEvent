using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;

namespace TicketService.Application.Interfaces.Repositories;

public interface ITicketRepository
{
    // ── Reservations ──────────────────────────────────────────
    Task<Reservation?> GetReservationByIdAsync(int reservationId);
    Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, ReservationFilterDto filter);  // use filter DTO
    Task<Reservation> CreateReservationAsync(Reservation reservation);
    Task UpdateReservationAsync(Reservation reservation);
    Task<List<Reservation>> GetExpiredReservationsAsync();
    Task<bool> HasActiveReservationAsync(int userId, int eventTicketId);   // missing — prevent duplicate reservations
    Task<List<Reservation>> GetActiveReservationsByUserAsync(int userId);
    Task<List<Reservation>> GetActiveReservationsByEventAsync(int eventId);


    // ── Event Tickets ─────────────────────────────────────────
    Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId);
    Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId);      // missing — list all ticket types for event
    Task UpdateEventTicketAsync(EventTicket eventTicket);                  // missing — for Reserve/Release

    // ── Issued Tickets ────────────────────────────────────────
    Task<Ticket?> GetTicketByIdAsync(int ticketId);
    Task<Ticket?> GetTicketByQrCodeAsync(string qrCode);
    Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId);
    Task<PagedResult<Ticket>> GetUserTicketsAsync(int userId, TicketFilterDto filter);     // use filter DTO
    Task<PagedResult<Ticket>> GetEventTicketsAsync(int eventId, TicketFilterDto filter);   // use filter DTO
    Task AddTicketsAsync(IEnumerable<Ticket> tickets);
    Task UpdateTicketAsync(Ticket ticket);

    // ── Payments ──────────────────────────────────────────────
    Task AddPaymentDetailAsync(PaymentDetail payment);
    Task<List<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId);   // missing — needed for refund flows
    Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId);    // missing — idempotency check
}
