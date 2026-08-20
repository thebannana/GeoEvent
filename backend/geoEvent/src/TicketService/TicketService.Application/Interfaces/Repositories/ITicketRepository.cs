using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Persistence;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;

namespace TicketService.Application.Interfaces.Repositories;

public interface ITicketRepository
{
    Task<List<ManageableEventAttendeePreviewDto>>
    GetManageableEventAttendeesForEventAsync(int eventId);
    Task<PagedResult<Reservation>> GetRefundRequestsAsync(AdminRefundRequestsQueryDto query);
    Task<Reservation?> GetReservationByIdAsync(int reservationId);
    Task<Reservation?> GetReservationByIdForUpdateAsync(int reservationId);

    Task UpdateReservationAsync(Reservation reservation);
    Task UpdateTicketAsync(Ticket ticket);
    Task UpdateEventTicketAsync(EventTicket eventTicket);
    Task<PagedResult<ManageableEventAttendeePreviewDto>> GetManageableEventAttendeesAsync(
    int eventId,
    int page,
    int pageSize,
    string? searchTerm);
    Task<AdminDashboardTicketStatsDto> GetAdminDashboardTicketStatsAsync(string currency = "BAM");
    Task ExecuteInStrategyAsync(Func<Task> operation);
    Task<IAppTransaction> BeginTransactionAsync();
    Task SaveChangesAsync();
    Task<Ticket?> GetTicketForValidationForUpdateAsync(string qrCode);
    Task<EventTicket> CreateEventTicketAsync(EventTicket eventTicket);
    Task<Reservation> CreateReservationAsync(Reservation reservation);
    Task AddTicketsAsync(IEnumerable<Ticket> tickets);
    Task AddPaymentDetailAsync(PaymentDetail payment);

    Task UpdatePaymentDetailAsync(PaymentDetail payment);

    Task<Reservation?> GetReservationByPendingProviderOrderIdAsync(string providerOrderId);
    Task<Reservation?> GetReservationByPendingProviderOrderIdForUpdateAsync(string providerOrderId);

    Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId);
    Task<EventTicket?> GetEventTicketByIdForUpdateAsync(int eventTicketId);

    Task<Ticket?> GetTicketByIdAsync(int ticketId);
    Task<Ticket?> GetTicketByQrCodeAsync(string qrCode);
    Task<Ticket?> GetTicketForValidationAsync(string qrCode);

    Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId);
    Task<List<Ticket>> GetTicketsByReservationForUpdateAsync(int reservationId);

    Task<List<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId);
    Task<List<PaymentDetail>> GetPaymentsByReservationForUpdateAsync(int reservationId);
    Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId);

    Task<PagedResult<EventAttendeePreviewDto>> GetPublicEventAttendeesAsync(int eventId, int page, int pageSize);
    Task<List<Reservation>> GetReservationsForEventAsync(int eventId);
    Task<PagedResult<Ticket>> GetTicketsByReservationAsync(int reservationId, int page, int pageSize);
    Task<PagedResult<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId, int page, int pageSize);
    Task<PagedResult<EventTicket>> GetEventTicketsByEventAsync(int eventId, int page, int pageSize);
    Task<PagedResult<Reservation>> GetEventReservationsAsync(int eventId, ReservationFilterDto filter);
    Task<int> GetEventCapacityAsync(int eventId);
    Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, ReservationFilterDto filter);
    Task<List<Reservation>> GetExpiredReservationsAsync();
    Task<PagedResult<Ticket>> GetUserTicketsAsync(int userId, TicketFilterDto filter);
    Task<PagedResult<Ticket>> GetEventTicketsAsync(int eventId, TicketFilterDto filter);
    Task<bool> HasActiveReservationAsync(int userId, int eventTicketId);
    Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId);
    Task<List<Reservation>> GetActiveReservationsByUserAsync(int userId);
    Task<List<Reservation>> GetActiveReservationsByEventAsync(int eventId);
    Task<int> GetEventReservationCountAsync(int eventId, ReservationStatus? status = null);
    Task<int> GetEventReservedQuantityAsync(int eventId, params ReservationStatus[] statuses);
}