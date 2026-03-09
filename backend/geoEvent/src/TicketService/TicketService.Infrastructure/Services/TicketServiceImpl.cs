using System.Security.Cryptography;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Repositories;
using TicketService.Application.Interfaces.Services;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;

namespace TicketService.Infrastructure.Services;

public class TicketServiceImpl : ITicketService
{
    private readonly ITicketRepository _repository;

    public TicketServiceImpl(ITicketRepository repository)
    {
        _repository = repository;
    }

    public async Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(
        CreateReservationDto dto, int userId, decimal pricePerTicket)
    {
        var eventTicket = await _repository.GetEventTicketByEventAndTypeAsync(dto.EventId, dto.TicketType);
        var totalAmount = dto.Quantity * pricePerTicket;
        var expiresAt = DateTime.UtcNow.AddMinutes(15);

        var reservation = new Reservation
        {
            ReservedAt = DateTime.UtcNow,
            EventId = dto.EventId,
            UserId = userId,
            EventTicketId = eventTicket?.TicketId,
            Quantity = dto.Quantity,
            TotalAmount = totalAmount,
            Currency = dto.Currency,
            Status = ReservationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = expiresAt,
            Notes = dto.Notes
        };

        await _repository.CreateReservationAsync(reservation);
        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
    }

    public async Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
        int reservationId, ConfirmReservationDto dto, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<ReservationResponseDto>.Forbidden("Not your reservation.");

        if (reservation.Status != ReservationStatus.Pending)
            return ServiceResult<ReservationResponseDto>.Fail("Reservation is no longer pending.");

        if (reservation.IsExpired())
        {
            reservation.Expire();
            await _repository.UpdateReservationAsync(reservation);
            return ServiceResult<ReservationResponseDto>.Fail("Reservation has expired.");
        }

        var payment = new PaymentDetail
        {
            PaidAt = DateTime.UtcNow,
            ReservationId = reservationId,
            UserId = userId,
            Status = "Completed",
            Method = "Card",
            Amount = reservation.TotalAmount,
            TransactionId = dto.PaymentReference,
            Currency = reservation.Currency
        };
        await _repository.AddPaymentDetailAsync(payment);

        reservation.Confirm(dto.PaymentReference);
        await _repository.UpdateReservationAsync(reservation);

        // Issue tickets (one per quantity) with QR codes
        var tickets = new List<Ticket>();
        var amountPerTicket = reservation.TotalAmount / reservation.Quantity;
        for (var i = 0; i < reservation.Quantity; i++)
        {
            tickets.Add(new Ticket
            {
                ReservationId = reservation.ReservationId,
                UserId = userId,
                EventId = reservation.EventId,
                TicketType = reservation.EventTicket?.TicketType ?? "General",
                QrCode = GenerateQrCode(),
                Amount = amountPerTicket,
                Currency = reservation.Currency,
                Status = TicketStatus.Active,
                IssuedAt = DateTime.UtcNow,
                SeatNumber = null,
                Section = null
            });
        }
        await _repository.AddTicketsAsync(tickets);

        var updated = await _repository.GetReservationByIdAsync(reservationId);
        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(updated!));
    }

    public async Task<ServiceResult<bool>> CancelReservationAsync(int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<bool>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your reservation.");

        if (reservation.Status is ReservationStatus.Cancelled or ReservationStatus.Expired)
            return ServiceResult<bool>.Fail("Reservation cannot be cancelled.");

        reservation.Cancel();
        await _repository.UpdateReservationAsync(reservation);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<ReservationResponseDto>.Forbidden("Not your reservation.");

        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
    }

    public async Task<ServiceResult<PagedResult<ReservationResponseDto>>> GetUserReservationsAsync(
        int userId, int page, int pageSize)
    {
        var paged = await _repository.GetUserReservationsAsync(userId, page, pageSize);
        var items = paged.Items.Select(MapToReservationResponse).ToList();
        return ServiceResult<PagedResult<ReservationResponseDto>>.Ok(new PagedResult<ReservationResponseDto>
        {
            Items = items,
            TotalCount = paged.TotalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    public async Task<ServiceResult<TicketResponseDto>> GetTicketAsync(int ticketId, int userId)
    {
        var ticket = await _repository.GetTicketByIdAsync(ticketId);
        if (ticket is null)
            return ServiceResult<TicketResponseDto>.NotFound("Ticket not found.");

        if (ticket.UserId != userId)
            return ServiceResult<TicketResponseDto>.Forbidden("Not your ticket.");

        return ServiceResult<TicketResponseDto>.Ok(MapToTicketResponse(ticket));
    }

    public async Task<ServiceResult<List<TicketResponseDto>>> GetUserTicketsAsync(int userId)
    {
        var tickets = await _repository.GetUserTicketsAsync(userId);
        return ServiceResult<List<TicketResponseDto>>.Ok(tickets.Select(MapToTicketResponse).ToList());
    }

    public async Task<ServiceResult<TicketResponseDto>> ValidateTicketAsync(string qrCode)
    {
        var ticket = await _repository.GetTicketByQrCodeAsync(qrCode);
        if (ticket is null)
            return ServiceResult<TicketResponseDto>.NotFound("Ticket not found.");

        if (!ticket.IsValid())
            return ServiceResult<TicketResponseDto>.Fail("Ticket is not valid (used or cancelled).");

        return ServiceResult<TicketResponseDto>.Ok(MapToTicketResponse(ticket));
    }

    public async Task<ServiceResult<bool>> CancelTicketAsync(int ticketId, int userId)
    {
        var ticket = await _repository.GetTicketByIdAsync(ticketId);
        if (ticket is null)
            return ServiceResult<bool>.NotFound("Ticket not found.");

        if (ticket.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your ticket.");

        if (!ticket.IsValid())
            return ServiceResult<bool>.Fail("Ticket cannot be cancelled.");

        ticket.Cancel();
        await _repository.UpdateTicketAsync(ticket);
        return ServiceResult<bool>.Ok(true);
    }

    private static string GenerateQrCode()
    {
        var bytes = new byte[32];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes).Replace("+", "-").Replace("/", "_").TrimEnd('=');
    }

    private static ReservationResponseDto MapToReservationResponse(Reservation r) => new()
    {
        ReservationId = r.ReservationId,
        UserId = r.UserId,
        EventId = r.EventId,
        Quantity = r.Quantity,
        TotalAmount = r.TotalAmount,
        Currency = r.Currency,
        Status = r.Status.ToString(),
        CreatedAt = r.CreatedAt,
        ConfirmedAt = r.ConfirmedAt,
        ExpiresAt = r.ExpiresAt,
        PaymentReference = r.PaymentReference,
        Notes = r.Notes,
        Tickets = r.Tickets?.Select(MapToTicketResponse).ToList() ?? []
    };

    private static TicketResponseDto MapToTicketResponse(Ticket t) => new()
    {
        TicketId = t.TicketId,
        ReservationId = t.ReservationId,
        UserId = t.UserId,
        EventId = t.EventId,
        TicketType = t.TicketType,
        QrCode = t.QrCode,
        Amount = t.Amount,
        Currency = t.Currency,
        Status = t.Status.ToString(),
        IssuedAt = t.IssuedAt,
        UsedAt = t.UsedAt,
        SeatNumber = t.SeatNumber,
        Section = t.Section
    };
}
