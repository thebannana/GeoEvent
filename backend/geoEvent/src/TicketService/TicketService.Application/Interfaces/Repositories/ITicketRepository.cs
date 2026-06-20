using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;

public interface ITicketRepository
{
    Task<List<Reservation>> GetReservationsForEventAsync(int eventId);
    Task<int> GetEventCapacityAsync(int eventId);
    Task<int> GetEventReservedQuantityAsync(int eventId, params ReservationStatus[] statuses);
    Task<int> GetEventReservationCountAsync(int eventId, ReservationStatus? status = null);

    Task<Reservation?> GetReservationByIdAsync(int reservationId);
    Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, ReservationFilterDto filter);
    Task<Reservation> CreateReservationAsync(Reservation reservation);
    Task UpdateReservationAsync(Reservation reservation);
    Task<List<Reservation>> GetExpiredReservationsAsync();
    Task<bool> HasActiveReservationAsync(int userId, int eventTicketId);
    Task<List<Reservation>> GetActiveReservationsByUserAsync(int userId);
    Task<List<Reservation>> GetActiveReservationsByEventAsync(int eventId);

    Task<EventTicket> CreateEventTicketAsync(EventTicket eventTicket);
    Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId);
    Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId);
    Task UpdateEventTicketAsync(EventTicket eventTicket);

    Task<Ticket?> GetTicketByIdAsync(int ticketId);
    Task<Ticket?> GetTicketByQrCodeAsync(string qrCode);
    Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId);
    Task<PagedResult<Ticket>> GetUserTicketsAsync(int userId, TicketFilterDto filter);
    Task<PagedResult<Ticket>> GetEventTicketsAsync(int eventId, TicketFilterDto filter);
    Task AddTicketsAsync(IEnumerable<Ticket> tickets);
    Task UpdateTicketAsync(Ticket ticket);
    Task<Ticket?> GetTicketForValidationAsync(string qrCode);

    Task AddPaymentDetailAsync(PaymentDetail payment);
    Task<List<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId);
    Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId);

    Task<PagedResult<Reservation>> GetEventReservationsAsync(int eventId, ReservationFilterDto filter);
}