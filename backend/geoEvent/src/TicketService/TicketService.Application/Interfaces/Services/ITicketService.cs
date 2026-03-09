using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface ITicketService
{
    // Reservations
    Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(
        CreateReservationDto dto, int userId, decimal pricePerTicket);
    Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
        int reservationId, ConfirmReservationDto dto, int userId);
    Task<ServiceResult<bool>> CancelReservationAsync(int reservationId, int userId);
    Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(
        int reservationId, int userId);
    Task<ServiceResult<PagedResult<ReservationResponseDto>>> GetUserReservationsAsync(
        int userId, int page, int pageSize);

    // Tickets
    Task<ServiceResult<TicketResponseDto>> GetTicketAsync(int ticketId, int userId);
    Task<ServiceResult<List<TicketResponseDto>>> GetUserTicketsAsync(int userId);
    Task<ServiceResult<TicketResponseDto>> ValidateTicketAsync(string qrCode);
    Task<ServiceResult<bool>> CancelTicketAsync(int ticketId, int userId);
}
