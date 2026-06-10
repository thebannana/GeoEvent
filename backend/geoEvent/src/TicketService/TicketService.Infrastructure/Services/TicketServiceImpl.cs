using System.Security.Cryptography;
using MassTransit;
using Microsoft.AspNetCore.Http;
using Shared.Contracts.Events;
using Shared.Contracts.Reservations;
using Shared.Contracts.Tickets;
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
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IUserDirectoryService _userDirectoryService;
    private readonly IEventAuthorizationService _eventAuthorizationService;

    public TicketServiceImpl(
        ITicketRepository repository,
        IPublishEndpoint publishEndpoint,
        IUserDirectoryService userDirectoryService,
        IEventAuthorizationService eventAuthorization)
    {
        _repository = repository;
        _publishEndpoint = publishEndpoint;
        _userDirectoryService = userDirectoryService;
        _eventAuthorizationService = eventAuthorization;
    }

    public async Task CancelUserReservationsAsync(int userId)
    {
        var reservations = await _repository.GetActiveReservationsByUserAsync(userId);

        foreach (var reservation in reservations)
        {
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

            var tickets = await _repository.GetTicketsByReservationAsync(reservation.ReservationId);

            foreach (var ticket in tickets.Where(t => t.CanBeCancelled()))
            {
                ticket.Cancel();
                await _repository.UpdateTicketAsync(ticket);

                await _publishEndpoint.Publish(new TicketCancelledMessage(
                    ticket.TicketId,
                    reservation.EventId,
                    reservation.UserId,
                    "User account action",
                    DateTime.UtcNow));
            }

            if (reservation.CanBeCancelled())
            {
                reservation.Cancel();
                await _repository.UpdateReservationAsync(reservation);
            }
        }
    }

    public async Task<ServiceResult<List<EventAttendeePreviewDto>>> GetPublicEventAttendeesAsync(int eventId)
    {
        var reservations = await _repository.GetReservationsForEventAsync(eventId);

        var attendees = reservations
            .Where(r => r.Status == ReservationStatus.Confirmed)
            .GroupBy(r => r.UserId)
            .Select(g => new EventAttendeePreviewDto
            {
                UserId = g.Key,
                Quantity = g.Sum(x => x.Quantity)
            })
            .ToList();

        if (attendees.Count == 0)
            return ServiceResult<List<EventAttendeePreviewDto>>.Ok(attendees);

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(
            attendees.Select(a => a.UserId).Distinct().ToList());

        var profilesById = profiles.ToDictionary(x => x.UserId);

        foreach (var attendee in attendees)
        {
            if (!profilesById.TryGetValue(attendee.UserId, out var profile))
                continue;

            attendee.Username = profile.Username;
            attendee.AvatarUrl = profile.ImageUrl;
        }

        return ServiceResult<List<EventAttendeePreviewDto>>.Ok(attendees);
    }

    public async Task CancelTicketsByEventAsync(int eventId)
    {
        var reservations = await _repository.GetActiveReservationsByEventAsync(eventId);

        foreach (var reservation in reservations)
        {
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

            var tickets = await _repository.GetTicketsByReservationAsync(reservation.ReservationId);

            foreach (var ticket in tickets.Where(t => t.CanBeCancelled()))
            {
                ticket.Cancel();
                await _repository.UpdateTicketAsync(ticket);

                await _publishEndpoint.Publish(new TicketCancelledMessage(
                    ticket.TicketId,
                    eventId,
                    reservation.UserId,
                    "Event cancelled",
                    DateTime.UtcNow));
            }

            if (reservation.CanBeCancelled())
            {
                reservation.Cancel();
                await _repository.UpdateReservationAsync(reservation);
            }
        }
    }

    public async Task<ServiceResult<ReservationResponseDto>> CreateReservationAsync(
        CreateReservationDto dto, int userId)
    {
        if (dto.Quantity <= 0 || dto.Quantity > 10)
            return ServiceResult<ReservationResponseDto>.Fail(
                "Quantity must be between 1 and 10.");

        var eventTicket = await _repository.GetEventTicketByIdAsync(dto.EventTicketId);
        if (eventTicket is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Ticket type not found.");

        if (!eventTicket.IsAvailable())
            return ServiceResult<ReservationResponseDto>.Fail(
                "This ticket type is not available.",
                StatusCodes.Status409Conflict);

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

        await _publishEndpoint.Publish(new ReservationCreatedMessage(
            created.ReservationId,
            created.EventId,
            created.UserId,
            created.EventTicketId!.Value,
            eventTicket.TicketType,
            created.Quantity,
            created.TotalAmount,
            created.Currency,
            created.ExpiresAt,
            created.CreatedAt));

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

        var expectedAmount = reservation.TotalAmount;
        if (dto.Amount != expectedAmount)
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Payment amount mismatch. Expected {expectedAmount} {reservation.Currency}.");

        if (!string.Equals(dto.Currency, reservation.Currency, StringComparison.OrdinalIgnoreCase))
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Currency mismatch. Expected {reservation.Currency}.");

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

        var amountPerTicket = reservation.TotalAmount / reservation.Quantity;
        var tickets = Enumerable.Range(0, reservation.Quantity)
            .Select(_ => new Ticket
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
            })
            .ToList();

        await _repository.AddTicketsAsync(tickets);

        await _publishEndpoint.Publish(new PaymentSucceededMessage(
            payment.PaymentId,
            reservationId,
            userId,
            payment.Amount,
            payment.Currency,
            payment.TransactionId!,
            payment.PaidAt));

        foreach (var ticket in tickets)
        {
            await _publishEndpoint.Publish(new TicketPurchasedMessage(
                ticket.TicketId,
                reservationId,
                reservation.EventId,
                userId,
                ticket.TicketType,
                ticket.Amount,
                ticket.Currency,
                ticket.IssuedAt));
        }

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

        if (reservation.EventTicketId.HasValue)
        {
            var eventTicket = await _repository.GetEventTicketByIdAsync(reservation.EventTicketId.Value);
            if (eventTicket is not null)
            {
                eventTicket.Release(reservation.Quantity);
                await _repository.UpdateEventTicketAsync(eventTicket);
            }
        }

        var tickets = await _repository.GetTicketsByReservationAsync(reservationId);
        foreach (var ticket in tickets.Where(t => t.CanBeCancelled()))
        {
            ticket.Cancel();
            await _repository.UpdateTicketAsync(ticket);

            await _publishEndpoint.Publish(new TicketCancelledMessage(
                ticket.TicketId,
                reservation.EventId,
                userId,
                "Reservation cancelled by user",
                DateTime.UtcNow));
        }

        reservation.Cancel();
        await _repository.UpdateReservationAsync(reservation);

        await _publishEndpoint.Publish(new ReservationCancelledIntegrationMessage(
            reservation.ReservationId,
            reservation.EventId,
            reservation.UserId,
            DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<ReservationResponseDto>> GetReservationAsync(
        int reservationId, int userId)
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
        return ServiceResult<PagedResult<ReservationResponseDto>>.Ok(
            new PagedResult<ReservationResponseDto>
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
        return ServiceResult<PagedResult<TicketResponseDto>>.Ok(
            new PagedResult<TicketResponseDto>
            {
                Items = paged.Items.Select(MapToTicketResponse),
                TotalCount = paged.TotalCount,
                Page = paged.Page,
                PageSize = paged.PageSize
            });
    }

    public async Task<ServiceResult<TicketScanResultDto>> ValidateTicketScanAsync(
    ValidateTicketScanDto dto,
    int validatorUserId,
    string validatorRole)
    {
        if (dto.EventId <= 0)
            return ServiceResult<TicketScanResultDto>.Fail("Invalid event id.");

        if (string.IsNullOrWhiteSpace(dto.QrCode) || dto.QrCode.Length > 128)
            return ServiceResult<TicketScanResultDto>.Fail("Invalid QR code format.");

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            dto.EventId,
            validatorUserId,
            validatorRole);

        if (!allowed)
        {
            return ServiceResult<TicketScanResultDto>.Forbidden(
                "You are not allowed to scan tickets for this event.");
        }

        var ticket = await _repository.GetTicketForValidationAsync(dto.QrCode);
        if (ticket is null)
        {
            return ServiceResult<TicketScanResultDto>.Ok(new TicketScanResultDto
            {
                IsValid = false,
                Status = "invalid",
                Message = "Ticket not found.",
                EventId = dto.EventId,
                ScannedAt = DateTime.UtcNow
            });
        }

        if (ticket.EventId != dto.EventId)
        {
            return ServiceResult<TicketScanResultDto>.Ok(new TicketScanResultDto
            {
                IsValid = false,
                Status = "wrong_event",
                Message = "This ticket belongs to another event.",
                TicketId = ticket.TicketId,
                ReservationId = ticket.ReservationId,
                EventId = ticket.EventId,
                UserId = ticket.UserId,
                TicketType = ticket.TicketType,
                IssuedAt = ticket.IssuedAt,
                UsedAt = ticket.UsedAt,
                ScannedAt = DateTime.UtcNow
            });
        }

        if (ticket.Status == TicketStatus.Used)
        {
            var usedResult = await BuildScanResultAsync(
                ticket,
                false,
                "already_used",
                "Ticket has already been used.");

            return ServiceResult<TicketScanResultDto>.Ok(usedResult);
        }

        if (ticket.Status == TicketStatus.Cancelled)
        {
            var cancelledResult = await BuildScanResultAsync(
                ticket,
                false,
                "cancelled",
                "Ticket has been cancelled.");

            return ServiceResult<TicketScanResultDto>.Ok(cancelledResult);
        }

        if (!ticket.CanBeUsed())
        {
            var invalidResult = await BuildScanResultAsync(
                ticket,
                false,
                "invalid",
                $"Ticket is not valid — current status: {ticket.Status}.");

            return ServiceResult<TicketScanResultDto>.Ok(invalidResult);
        }

        ticket.MarkAsUsed();
        await _repository.UpdateTicketAsync(ticket);

        var validResult = await BuildScanResultAsync(
            ticket,
            true,
            "valid",
            "Ticket is valid and has been checked in.");

        return ServiceResult<TicketScanResultDto>.Ok(validResult);
    }

    private async Task<TicketScanResultDto> BuildScanResultAsync(
    Ticket ticket,
    bool isValid,
    string status,
    string message)
    {
        string? username = null;
        string? avatarUrl = null;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(new[] { ticket.UserId });
        var profile = profiles.FirstOrDefault();

        if (profile is not null)
        {
            username = profile.Username;
            avatarUrl = profile.ImageUrl;
        }

        return new TicketScanResultDto
        {
            IsValid = isValid,
            Status = status,
            Message = message,
            TicketId = ticket.TicketId,
            ReservationId = ticket.ReservationId,
            EventId = ticket.EventId,
            UserId = ticket.UserId,
            TicketType = ticket.TicketType,
            ParticipantUsername = username,
            ParticipantAvatarUrl = avatarUrl,
            IssuedAt = ticket.IssuedAt,
            UsedAt = ticket.UsedAt,
            ScannedAt = DateTime.UtcNow
        };
    }

    public async Task<ServiceResult<bool>> ExpireReservationsAsync()
    {
        var expired = await _repository.GetExpiredReservationsAsync();

        foreach (var reservation in expired)
        {
            if (reservation.EventTicketId.HasValue)
            {
                var eventTicket = await _repository.GetEventTicketByIdAsync(reservation.EventTicketId.Value);
                if (eventTicket is not null)
                {
                    eventTicket.Release(reservation.Quantity);
                    await _repository.UpdateEventTicketAsync(eventTicket);
                }
            }

            reservation.Expire();
            await _repository.UpdateReservationAsync(reservation);

            await _publishEndpoint.Publish(new ReservationExpiredMessage(
                reservation.ReservationId,
                reservation.EventId,
                reservation.UserId,
                DateTime.UtcNow));
        }

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<List<EventTicketResponseDto>>> GetEventTicketsAsync(int eventId)
    {
        var tickets = await _repository.GetEventTicketsByEventAsync(eventId);
        return ServiceResult<List<EventTicketResponseDto>>.Ok(
            tickets.Select(MapToEventTicketResponse).ToList());
    }

    public async Task<ServiceResult<EventTicketResponseDto>> GetEventTicketAsync(int eventId, int eventTicketId)
    {
        if (eventId <= 0)
            return ServiceResult<EventTicketResponseDto>.Fail("Invalid event id.");

        if (eventTicketId <= 0)
            return ServiceResult<EventTicketResponseDto>.Fail("Invalid event ticket id.");

        var ticket = await _repository.GetEventTicketByIdAsync(eventTicketId);
        if (ticket is null || ticket.EventId != eventId)
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

        await _publishEndpoint.Publish(new TicketCancelledMessage(
            ticket.TicketId,
            ticket.EventId,
            userId,
            "Cancelled by user",
            DateTime.UtcNow));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<PagedResult<OrganizerReservationResponseDto>>> GetEventReservationsAsync(
    int eventId,
    int requesterId,
    string requesterRole,
    ReservationFilterDto filter)
    {
        if (eventId <= 0)
            return ServiceResult<PagedResult<OrganizerReservationResponseDto>>.Fail("Invalid event id.");

        var isAdmin = string.Equals(requesterRole, "Admin", StringComparison.OrdinalIgnoreCase);
        var isOrganizer = string.Equals(requesterRole, "Organizer", StringComparison.OrdinalIgnoreCase);

        if (!isAdmin && !isOrganizer)
        {
            return ServiceResult<PagedResult<OrganizerReservationResponseDto>>.Forbidden(
                "You are not allowed to view event reservations.");
        }

        var paged = await _repository.GetEventReservationsAsync(eventId, filter);

        var items = paged.Items.Select(MapToOrganizerReservationResponse).ToList();
        await EnrichParticipantPreviewAsync(items);

        return ServiceResult<PagedResult<OrganizerReservationResponseDto>>.Ok(
            new PagedResult<OrganizerReservationResponseDto>
            {
                Items = items,
                TotalCount = paged.TotalCount,
                Page = paged.Page,
                PageSize = paged.PageSize
            });
    }

    public async Task<ServiceResult<ReservationResponseDto>> CompleteCheckoutAsync(
    CompleteCheckoutDto dto,
    int userId)
    {
        var eventTicket = await _repository.GetEventTicketByIdAsync(dto.EventTicketId);
        if (eventTicket is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Ticket type not found.");

        if (!eventTicket.IsAvailable() || dto.Quantity > eventTicket.AvailableQuantity)
            return ServiceResult<ReservationResponseDto>.Fail(
                "Ticket no longer available.",
                StatusCodes.Status409Conflict);

        var expectedAmount = eventTicket.Price * dto.Quantity;
        if (dto.Amount != expectedAmount)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Payment amount mismatch. Expected {expectedAmount} {dto.Currency}.");
        }

        var existingPayment = await _repository.GetPaymentByTransactionIdAsync(dto.PaymentReference);
        if (existingPayment is not null)
            return ServiceResult<ReservationResponseDto>.Conflict(
                "This payment reference has already been processed.");

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
            ExpiresAt = DateTime.UtcNow.AddMinutes(15)
        };

        var created = await _repository.CreateReservationAsync(reservation);

        var payment = new PaymentDetail
        {
            PaidAt = DateTime.UtcNow,
            ReservationId = created.ReservationId,
            UserId = userId,
            Status = PaymentStatus.Completed,
            Method = dto.PaymentMethod,
            Amount = dto.Amount,
            TransactionId = dto.PaymentReference,
            Currency = dto.Currency
        };

        await _repository.AddPaymentDetailAsync(payment);

        created.Confirm(dto.PaymentReference);
        await _repository.UpdateReservationAsync(created);

        var amountPerTicket = created.TotalAmount / created.Quantity;
        var tickets = Enumerable.Range(0, created.Quantity)
            .Select(_ => new Ticket
            {
                ReservationId = created.ReservationId,
                UserId = userId,
                EventId = created.EventId,
                TicketType = eventTicket.TicketType,
                QrCode = GenerateQrCode(),
                Amount = amountPerTicket,
                Currency = created.Currency,
                Status = TicketStatus.Active,
                IssuedAt = DateTime.UtcNow
            })
            .ToList();

        await _repository.AddTicketsAsync(tickets);

        await _publishEndpoint.Publish(new ReservationConfirmedMessage(
            created.ReservationId,
            created.EventId,
            created.UserId,
            created.Quantity,
            DateTime.UtcNow
        ));

        await _publishEndpoint.Publish(new PaymentSucceededMessage(
            payment.PaymentId,
            created.ReservationId,
            userId,
            payment.Amount,
            payment.Currency,
            payment.TransactionId!,
            payment.PaidAt
        ));

        foreach (var ticket in tickets)
        {
            await _publishEndpoint.Publish(new TicketPurchasedMessage(
                ticket.TicketId,
                created.ReservationId,
                created.EventId,
                userId,
                ticket.TicketType,
                ticket.Amount,
                ticket.Currency,
                ticket.IssuedAt
            ));
        }

        var updated = await _repository.GetReservationByIdAsync(created.ReservationId);
        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(updated!));
    }
    public async Task<ServiceResult<EventReservationSummaryResponseDto>> GetEventReservationSummaryAsync(
    int eventId,
    int requesterId,
    string requesterRole)
    {
        if (eventId <= 0)
            return ServiceResult<EventReservationSummaryResponseDto>.Fail("Invalid event id.", 400);

        var isAdmin = string.Equals(requesterRole, "Admin", StringComparison.OrdinalIgnoreCase);
        var isOrganizer = string.Equals(requesterRole, "Organizer", StringComparison.OrdinalIgnoreCase);

        if (!isAdmin && !isOrganizer)
        {
            return ServiceResult<EventReservationSummaryResponseDto>.Forbidden(
                "You are not allowed to view event reservation summary.");
        }

        var capacity = await _repository.GetEventCapacityAsync(eventId);
        var pendingCount = await _repository.GetEventReservedQuantityAsync(eventId, ReservationStatus.Pending);
        var confirmedCount = await _repository.GetEventReservedQuantityAsync(eventId, ReservationStatus.Confirmed);
        var reservedCount = pendingCount + confirmedCount;
        var reservationCount = await _repository.GetEventReservationCountAsync(eventId);
        var availableCount = Math.Max(0, capacity - reservedCount);

        var response = new EventReservationSummaryResponseDto
        {
            EventId = eventId,
            Capacity = capacity,
            PendingCount = pendingCount,
            ConfirmedCount = confirmedCount,
            ReservedCount = reservedCount,
            AvailableCount = availableCount,
            ReservationCount = reservationCount,
            IsSoldOut = capacity > 0 && availableCount <= 0
        };

        return ServiceResult<EventReservationSummaryResponseDto>.Ok(response);
    }

    private async Task EnrichParticipantPreviewAsync(List<OrganizerReservationResponseDto> items)
    {
        var userIds = items
            .Select(x => x.UserId)
            .Where(x => x > 0)
            .Distinct()
            .ToList();

        if (userIds.Count == 0)
            return;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(userIds);
        var byId = profiles.ToDictionary(x => x.UserId);

        foreach (var item in items)
        {
            if (!byId.TryGetValue(item.UserId, out var profile))
                continue;

            item.ParticipantUsername = profile.Username;
            item.ParticipantAvatarUrl = profile.ImageUrl;
        }
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

    private static OrganizerReservationResponseDto MapToOrganizerReservationResponse(Reservation r) => new()
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
        Notes = r.Notes
    };
}