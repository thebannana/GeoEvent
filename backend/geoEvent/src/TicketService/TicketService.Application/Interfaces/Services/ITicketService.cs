using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface ITicketService
{
    // ── Reservations ──────────────────────────────────────────
    Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(
        CreateReservationDto dto, int userId);                             // remove pricePerTicket — service resolves from EventTicket

    Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
        int reservationId, ConfirmReservationDto dto, int userId);

    Task<ServiceResult<bool>> CancelReservationAsync(
        int reservationId, int userId);

    Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(
        int reservationId, int userId);

    Task<ServiceResult<PagedResult<ReservationResponseDto>>> GetUserReservationsAsync(
        int userId, ReservationFilterDto filter);                          // use filter DTO

    Task<ServiceResult<bool>> ExpireReservationsAsync();                   // missing — background job trigger

    // ── Event Tickets ─────────────────────────────────────────
    Task<ServiceResult<List<EventTicketResponseDto>>> GetEventTicketsAsync(int eventId);  // missing — browse available types

    Task<ServiceResult<EventTicketResponseDto>> GetEventTicketAsync(int eventTicketId);  // missing

    // ── Issued Tickets ────────────────────────────────────────
    Task<ServiceResult<TicketResponseDto>> GetTicketAsync(
        int ticketId, int userId);

    Task<ServiceResult<PagedResult<TicketResponseDto>>> GetUserTicketsAsync(
        int userId, TicketFilterDto filter);                               // use filter DTO + paging

    Task<ServiceResult<List<TicketResponseDto>>> GetTicketsByReservationAsync(
        int reservationId, int userId);                                    // missing

    Task<ServiceResult<TicketResponseDto>> ValidateTicketAsync(
        string qrCode, int validatorUserId);                               // add validatorUserId — staff/organizer only

    Task<ServiceResult<bool>> CancelTicketAsync(
        int ticketId, int userId);

    // ── Payments ──────────────────────────────────────────────
    Task<ServiceResult<List<PaymentDetailResponseDto>>> GetReservationPaymentsAsync(
        int reservationId, int userId);                                    // missing
}
