using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface ITicketService
{
    Task<ServiceResult<bool>>
    ExpireEventDataAsync(
        int eventId,
        CancellationToken cancellationToken = default);
    Task<ServiceResult<PagedResult<AdminRefundRequestResponseDto>>> GetAdminRefundRequestsAsync(
    AdminRefundRequestsQueryDto query,
    int requesterId,
    string requesterRole);
    Task<ServiceResult<PagedResult<ManageableEventAttendeePreviewDto>>> GetManageableEventAttendeesAsync(
    int eventId,
    ManageableEventAttendeesFilterDto? filter);
    Task<ServiceResult<AdminDashboardTicketStatsDto>> GetAdminDashboardTicketStatsAsync(
    int requesterId,
    string requesterRole);
    Task<ServiceResult<EventTicketResponseDto>> CreateDefaultEventTicketAsync(
    CreateDefaultEventTicketRequest request);
    Task<ServiceResult<PagedResult<EventAttendeePreviewDto>>> GetPublicEventAttendeesAsync(
        int eventId,
        PublicEventAttendeesFilterDto filter);

    Task<ServiceResult<bool>> RemoveAttendeeReservationAsync(
        int eventId,
        int reservationId,
        int requesterId,
        string requesterRole);

    Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(CreateReservationDto dto, int userId);
    Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(int reservationId, ConfirmReservationDto dto, int userId);

    Task<ServiceResult<bool>> CancelReservationAsync(int reservationId, int userId);
    Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(int reservationId, int userId);

    Task<ServiceResult<PagedResult<ReservationResponseDto>>> GetUserReservationsAsync(int userId, ReservationFilterDto filter);

    Task<ServiceResult<bool>> AttachPendingPayPalOrderAsync(int reservationId, int userId, string providerOrderId);
    Task<ServiceResult<bool>> ExpireReservationsAsync();

    Task<ServiceResult<ReservationResponseDto>> MarkCashCollectedAsync(
        int eventId,
        int reservationId,
        int organizerUserId,
        string organizerRole);

    Task<ServiceResult<PagedResult<OrganizerReservationResponseDto>>> GetEventReservationsAsync(
        int eventId,
        int requesterId,
        string requesterRole,
        ReservationFilterDto filter);

    Task<ServiceResult<EventReservationSummaryResponseDto>> GetEventReservationSummaryAsync(
        int eventId,
        int requesterId,
        string requesterRole);

    Task<ServiceResult<PagedResult<EventTicketResponseDto>>> GetEventTicketsAsync(int eventId, int page, int pageSize);
    Task<ServiceResult<EventTicketResponseDto>> GetEventTicketAsync(int eventId, int eventTicketId);

    Task<ServiceResult<TicketResponseDto>> GetTicketAsync(int ticketId, int userId);

    Task<ServiceResult<PagedResult<TicketResponseDto>>> GetUserTicketsAsync(int userId, TicketFilterDto filter);

    Task<ServiceResult<PagedResult<TicketResponseDto>>> GetTicketsByReservationAsync(int reservationId, int userId, int page, int pageSize);

    Task<ServiceResult<TicketScanResultDto>> ValidateTicketScanAsync(
        ValidateTicketScanDto dto,
        int validatorUserId,
        string validatorRole);

    Task<ServiceResult<bool>> CancelTicketAsync(int ticketId, int userId);

    Task<ServiceResult<PagedResult<PaymentDetailResponseDto>>> GetReservationPaymentsAsync(int reservationId, int userId, int page, int pageSize);

    Task CancelUserReservationsAsync(int userId);
    Task CancelTicketsByEventAsync(int eventId);

    Task<ServiceResult<PayPalOrderResponseDto>> CreateReservationPayPalOrderAsync(int reservationId, int userId);

    Task<ServiceResult<ReservationResponseDto>> CaptureReservationPayPalOrderAsync(
        int reservationId,
        CapturePayPalOrderDto dto,
        int userId);

    Task<ServiceResult<ReservationResponseDto>> RequestRefundAsync(
        int reservationId,
        RequestRefundDto dto,
        int userId);

    Task<ServiceResult<ReservationResponseDto>> ApproveRefundAsync(
        int eventId,
        int reservationId,
        ApproveRefundDto dto,
        int organizerUserId,
        string organizerRole);

    Task<ServiceResult<ReservationResponseDto>> RejectRefundAsync(
        int eventId,
        int reservationId,
        RejectRefundDto dto,
        int organizerUserId,
        string organizerRole);
}