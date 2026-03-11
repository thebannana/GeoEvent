using System.Security.Cryptography;
using Microsoft.AspNetCore.Http;
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
    CreateReservationDto dto, int userId)
    {
        var eventTicket = await _repository.GetEventTicketByIdAsync(dto.EventTicketId);
        if (eventTicket is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Ticket type not found.");

        if (!eventTicket.IsAvailable())
            return ServiceResult<ReservationResponseDto>.Fail(
                "This ticket type is not available.", StatusCodes.Status409Conflict);

        if (dto.Quantity > eventTicket.AvailableQuantity)
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Only {eventTicket.AvailableQuantity} tickets available.");

        var hasActive = await _repository.HasActiveReservationAsync(userId, dto.EventTicketId);
        if (hasActive)
            return ServiceResult<ReservationResponseDto>.Conflict(
                "You already have an active reservation for this ticket type.");

        eventTicket.Reserve(dto.Quantity);
        await _repository.UpdateEventTicketAsync(eventTicket);

        var reservation = new Reservation
        {
            ReservedAt = DateTime.UtcNow,
            EventId = dto.EventId,
            UserId = userId,
            EventTicketId = dto.EventTicketId,
            Quantity = dto.Quantity,
            TotalAmount = eventTicket.Price * dto.Quantity,
            Currency = dto.Currency,
            Status = ReservationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddMinutes(15),
            Notes = dto.Notes
        };

        var created = await _repository.CreateReservationAsync(reservation);
        return ServiceResult<ReservationResponseDto>.Created(MapToReservationResponse(created));
    }


    public async Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
    int reservationId, ConfirmReservationDto dto, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<ReservationResponseDto>.Forbidden("Not your reservation.");

        if (!reservation.CanBeConfirmed())
            return ServiceResult<ReservationResponseDto>.Fail(
                reservation.IsExpired()
                    ? "Reservation has expired."
                    : "Reservation is no longer pending.");

        // Idempotency — prevent duplicate payments
        var existing = await _repository.GetPaymentByTransactionIdAsync(dto.PaymentReference);
        if (existing is not null)
            return ServiceResult<ReservationResponseDto>.Conflict(
                "This payment reference has already been processed.");

        var payment = new PaymentDetail
        {
            PaidAt = DateTime.UtcNow,
            ReservationId = reservationId,
            UserId = userId,
            Status = PaymentStatus.Completed,
            Method = dto.PaymentMethod,
            Amount = dto.Amount,
            TransactionId = dto.PaymentReference,
            Currency = dto.Currency
        };
        await _repository.AddPaymentDetailAsync(payment);

        reservation.Confirm(dto.PaymentReference);
        await _repository.UpdateReservationAsync(reservation);

        // Issue one ticket per quantity
        var amountPerTicket = reservation.TotalAmount / reservation.Quantity;
        var tickets = Enumerable.Range(0, reservation.Quantity).Select(_ => new Ticket
        {
            ReservationId = reservation.ReservationId,
            UserId = userId,
            EventId = reservation.EventId,
            TicketType = reservation.EventTicket?.TicketType ?? "General",
            QrCode = GenerateQrCode(),
            Amount = amountPerTicket,
            Currency = reservation.Currency,
            Status = TicketStatus.Active,
            IssuedAt = DateTime.UtcNow
        });
        await _repository.AddTicketsAsync(tickets);

        var updated = await _repository.GetReservationByIdAsync(reservationId);
        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(updated!));
    }


    public async Task<ServiceResult<bool>> CancelReservationAsync(
    int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<bool>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your reservation.");

        if (!reservation.CanBeCancelled())
            return ServiceResult<bool>.Fail("Reservation cannot be cancelled in its current state.");

        // Release inventory
        if (reservation.EventTicketId.HasValue)
        {
            var eventTicket = await _repository.GetEventTicketByIdAsync(
                reservation.EventTicketId.Value);
            if (eventTicket is not null)
            {
                eventTicket.Release(reservation.Quantity);
                await _repository.UpdateEventTicketAsync(eventTicket);
            }
        }

        // Cancel all issued tickets
        var tickets = await _repository.GetTicketsByReservationAsync(reservationId);
        foreach (var ticket in tickets.Where(t => t.CanBeCancelled()))
        {
            ticket.Cancel();
            await _repository.UpdateTicketAsync(ticket);
        }

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
    int userId, ReservationFilterDto filter)
    {
        var paged = await _repository.GetUserReservationsAsync(userId, filter);
        return ServiceResult<PagedResult<ReservationResponseDto>>.Ok(new PagedResult<ReservationResponseDto>
        {
            Items = paged.Items.Select(MapToReservationResponse),
            TotalCount = paged.TotalCount,
            Page = paged.Page,
            PageSize = paged.PageSize
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

    public async Task<ServiceResult<PagedResult<TicketResponseDto>>> GetUserTicketsAsync(
    int userId, TicketFilterDto filter)
    {
        var paged = await _repository.GetUserTicketsAsync(userId, filter);
        return ServiceResult<PagedResult<TicketResponseDto>>.Ok(new PagedResult<TicketResponseDto>
        {
            Items = paged.Items.Select(MapToTicketResponse),
            TotalCount = paged.TotalCount,
            Page = paged.Page,
            PageSize = paged.PageSize
        });
    }


    public async Task<ServiceResult<TicketResponseDto>> ValidateTicketAsync(
    string qrCode, int validatorUserId)
    {
        var ticket = await _repository.GetTicketByQrCodeAsync(qrCode);
        if (ticket is null)
            return ServiceResult<TicketResponseDto>.NotFound("Ticket not found.");

        if (!ticket.CanBeUsed())
            return ServiceResult<TicketResponseDto>.Fail(
                $"Ticket is not valid — current status: {ticket.Status}.");

        ticket.MarkAsUsed();
        await _repository.UpdateTicketAsync(ticket);

        return ServiceResult<TicketResponseDto>.Ok(MapToTicketResponse(ticket));
    }

    public async Task<ServiceResult<bool>> ExpireReservationsAsync()
    {
        var expired = await _repository.GetExpiredReservationsAsync();

        foreach (var reservation in expired)
        {
            // Release inventory
            if (reservation.EventTicketId.HasValue)
            {
                var eventTicket = await _repository.GetEventTicketByIdAsync(
                    reservation.EventTicketId.Value);
                if (eventTicket is not null)
                {
                    eventTicket.Release(reservation.Quantity);
                    await _repository.UpdateEventTicketAsync(eventTicket);
                }
            }

            reservation.Expire();
            await _repository.UpdateReservationAsync(reservation);
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<List<EventTicketResponseDto>>> GetEventTicketsAsync(int eventId)
    {
        var tickets = await _repository.GetEventTicketsByEventAsync(eventId);
        return ServiceResult<List<EventTicketResponseDto>>.Ok(
            tickets.Select(MapToEventTicketResponse).ToList());
    }

    public async Task<ServiceResult<EventTicketResponseDto>> GetEventTicketAsync(int eventTicketId)
    {
        var ticket = await _repository.GetEventTicketByIdAsync(eventTicketId);
        if (ticket is null)
            return ServiceResult<EventTicketResponseDto>.NotFound("Ticket type not found.");

        return ServiceResult<EventTicketResponseDto>.Ok(MapToEventTicketResponse(ticket));
    }

    public async Task<ServiceResult<List<TicketResponseDto>>> GetTicketsByReservationAsync(
    int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<List<TicketResponseDto>>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<List<TicketResponseDto>>.Forbidden("Not your reservation.");

        var tickets = await _repository.GetTicketsByReservationAsync(reservationId);
        return ServiceResult<List<TicketResponseDto>>.Ok(
            tickets.Select(MapToTicketResponse).ToList());
    }

    public async Task<ServiceResult<List<PaymentDetailResponseDto>>> GetReservationPaymentsAsync(
    int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<List<PaymentDetailResponseDto>>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<List<PaymentDetailResponseDto>>.Forbidden("Not your reservation.");

        var payments = await _repository.GetPaymentsByReservationAsync(reservationId);
        return ServiceResult<List<PaymentDetailResponseDto>>.Ok(
            payments.Select(MapToPaymentResponse).ToList());
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
        EventTicketId = r.EventTicketId,
        Quantity = r.Quantity,
        TotalAmount = r.TotalAmount,
        Currency = r.Currency,
        Status = r.Status.ToString(),
        CreatedAt = r.CreatedAt,
        ConfirmedAt = r.ConfirmedAt,
        CancelledAt = r.CancelledAt,
        ExpiredAt = r.ExpiredAt,
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
        CancelledAt = t.CancelledAt,
        SeatNumber = t.SeatNumber,
        Section = t.Section
    };

    private static EventTicketResponseDto MapToEventTicketResponse(EventTicket t) => new()
    {
        TicketId = t.TicketId,
        EventId = t.EventId,
        TicketType = t.TicketType,
        Price = t.Price,
        TotalQuantity = t.TotalQuantity,
        SoldQuantity = t.SoldQuantity,
        AvailableQuantity = t.AvailableQuantity,
        IsAvailable = t.IsAvailable(),
        SaleStartDate = t.SaleStartDate,
        SaleEndDate = t.SaleEndDate,
        IsActive = t.IsActive,
        Description = t.Description,
        PriceZoneId = t.PriceZoneId
    };

    private static PaymentDetailResponseDto MapToPaymentResponse(PaymentDetail p) => new()
    {
        PaymentId = p.PaymentId,
        ReservationId = p.ReservationId,
        UserId = p.UserId,
        Status = p.Status.ToString(),
        Method = p.Method.ToString(),
        Amount = p.Amount,
        Currency = p.Currency,
        TransactionId = p.TransactionId,
        PaidAt = p.PaidAt
    };

}
