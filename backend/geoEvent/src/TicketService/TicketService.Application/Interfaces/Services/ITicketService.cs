using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface ITicketService
{
    Task<ServiceResult<bool>> RemoveAttendeeReservationAsync(
    int eventId,
    int reservationId,
    int requesterId,
    string requesterRole);
    // Reservations
    Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(
        CreateReservationDto dto, int userId);

    Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
        int reservationId, ConfirmReservationDto dto, int userId);

    Task<ServiceResult<List<EventAttendeePreviewDto>>> GetPublicEventAttendeesAsync(int eventId);
    Task<ServiceResult<bool>> CancelReservationAsync(int reservationId, int userId);
    Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(
        int reservationId, int userId);

    Task<ServiceResult<PagedResult<ReservationResponseDto>>> GetUserReservationsAsync(
        int userId, ReservationFilterDto filter);

    Task<ServiceResult<bool>> ExpireReservationsAsync();

    Task<ServiceResult<PagedResult<OrganizerReservationResponseDto>>> GetEventReservationsAsync(
        int eventId,
        int requesterId,
        string requesterRole,
        ReservationFilterDto filter);

    Task<ServiceResult<EventReservationSummaryResponseDto>> GetEventReservationSummaryAsync(
        int eventId,
        int requesterId,
        string requesterRole);

    Task<ServiceResult<ReservationResponseDto>> CompleteCheckoutAsync(
    CompleteCheckoutDto dto,
    int userId);

    // Event tickets
    Task<ServiceResult<List<EventTicketResponseDto>>> GetEventTicketsAsync(int eventId);

    Task<ServiceResult<EventTicketResponseDto>> GetEventTicketAsync(int eventId, int eventTicketId);

    // Issued tickets
    Task<ServiceResult<TicketResponseDto>> GetTicketAsync(int ticketId, int userId);

    Task<ServiceResult<PagedResult<TicketResponseDto>>> GetUserTicketsAsync(
        int userId, TicketFilterDto filter);

    Task<ServiceResult<List<TicketResponseDto>>> GetTicketsByReservationAsync(
        int reservationId, int userId);

    Task<ServiceResult<TicketScanResultDto>> ValidateTicketScanAsync(
    ValidateTicketScanDto dto,
    int validatorUserId,
    string validatorRole);

    Task<ServiceResult<bool>> CancelTicketAsync(int ticketId, int userId);

    // Payments
    Task<ServiceResult<List<PaymentDetailResponseDto>>> GetReservationPaymentsAsync(
        int reservationId, int userId);

    // Consumers
    Task CancelUserReservationsAsync(int userId);
    Task CancelTicketsByEventAsync(int eventId);
}