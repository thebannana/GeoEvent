using MassTransit;
using MassTransit.Transports;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Reservations;
using Shared.Contracts.Tickets;
using System.Security.Cryptography;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
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
    private readonly IEventDirectoryClient _eventDirectoryClient;
    private readonly ILogger<TicketServiceImpl> _logger;
    private readonly IPayPalService _payPalService;

    public TicketServiceImpl(
        ITicketRepository repository,
        IPublishEndpoint publishEndpoint,
        IUserDirectoryService userDirectoryService,
        IEventAuthorizationService eventAuthorization,
        IEventDirectoryClient eventDirectoryClient,
        ILogger<TicketServiceImpl> logger,
        IPayPalService payPalService)
    {
        _repository = repository;
        _publishEndpoint = publishEndpoint;
        _userDirectoryService = userDirectoryService;
        _eventAuthorizationService = eventAuthorization;
        _eventDirectoryClient = eventDirectoryClient;
        _logger = logger;
        _payPalService = payPalService;
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
            created.CreatedAt
        ));

        await PublishReservationCreatedNotificationAsync(created, created.CreatedAt);

        _logger.LogInformation("Created reservation {ReservationId} for Event {EventId} by User {UserId}", created.ReservationId, dto.EventId, userId);

        return ServiceResult<ReservationResponseDto>.Created(MapToReservationResponse(created));
    }

    public async Task<ServiceResult<ReservationResponseDto>> ConfirmReservationAsync(
    int reservationId,
    ConfirmReservationDto dto,
    int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<ReservationResponseDto>.Forbidden("Not your reservation.");

        if (!reservation.CanBeConfirmed())
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                reservation.IsExpired() ? "Reservation has expired." : "Reservation is no longer pending.",
                StatusCodes.Status409Conflict);
        }

        if (!string.Equals(dto.Currency, reservation.Currency, StringComparison.OrdinalIgnoreCase))
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Currency mismatch. Expected {reservation.Currency}.",
                StatusCodes.Status400BadRequest);
        }

        PaymentDetail payment;
        var expectedAmount = reservation.TotalAmount;

        switch (dto.PaymentMethod)
        {
            case PaymentMethod.PayPal:
                {
                    if (string.IsNullOrWhiteSpace(dto.ProviderOrderId))
                    {
                        return ServiceResult<ReservationResponseDto>.Fail(
                            "Provider order ID is required for PayPal confirmation.",
                            StatusCodes.Status400BadRequest);
                    }

                    if (!string.Equals(reservation.PendingProviderOrderId, dto.ProviderOrderId, StringComparison.Ordinal))
                    {
                        return ServiceResult<ReservationResponseDto>.Fail(
                            "PayPal order does not match this reservation.",
                            StatusCodes.Status409Conflict);
                    }

                    if (string.IsNullOrWhiteSpace(dto.PaymentReference))
                    {
                        return ServiceResult<ReservationResponseDto>.Fail(
                            "Payment reference is required for PayPal confirmation.",
                            StatusCodes.Status400BadRequest);
                    }

                    if (string.IsNullOrWhiteSpace(dto.ProviderPaymentId))
                    {
                        return ServiceResult<ReservationResponseDto>.Fail(
                            "Provider payment ID is required for PayPal confirmation.",
                            StatusCodes.Status400BadRequest);
                    }

                    var existingPayPalPayment =
                        await _repository.GetPaymentByTransactionIdAsync(dto.PaymentReference);

                    if (existingPayPalPayment is not null)
                    {
                        return ServiceResult<ReservationResponseDto>.Conflict(
                            "This payment reference has already been processed.");
                    }

                    payment = new PaymentDetail
                    {
                        PaidAt = DateTime.UtcNow,
                        ReservationId = reservationId,
                        UserId = userId,
                        Status = PaymentStatus.Completed,
                        Method = PaymentMethod.PayPal,
                        Amount = expectedAmount,
                        TransactionId = dto.PaymentReference.Trim(),
                        ProviderPaymentId = dto.ProviderPaymentId.Trim(),
                        ProviderOrderId = dto.ProviderOrderId.Trim(),
                        Currency = reservation.Currency
                    };

                    break;
                }

            case PaymentMethod.Cash:
                {
                    var cashReference = $"cash-{reservationId}-{Guid.NewGuid():N}";
                    var existingCashPayment =
                        await _repository.GetPaymentByTransactionIdAsync(cashReference);

                    if (existingCashPayment is not null)
                    {
                        return ServiceResult<ReservationResponseDto>.Conflict(
                            "Cash payment reference collision. Please retry.");
                    }

                    payment = new PaymentDetail
                    {
                        PaidAt = null,
                        ReservationId = reservationId,
                        UserId = userId,
                        Status = PaymentStatus.Pending,
                        Method = PaymentMethod.Cash,
                        Amount = expectedAmount,
                        TransactionId = cashReference,
                        ProviderPaymentId = null,
                        ProviderOrderId = null,
                        Currency = reservation.Currency
                    };

                    dto.PaymentReference = cashReference;
                    break;
                }

            default:
                return ServiceResult<ReservationResponseDto>.Fail(
                    "Unsupported payment method.",
                    StatusCodes.Status400BadRequest);
        }

        await _repository.AddPaymentDetailAsync(payment);

        reservation.Confirm(payment.TransactionId!);
        await _repository.UpdateReservationAsync(reservation);

        var tickets = Enumerable.Range(0, reservation.Quantity)
            .Select(_ => new Ticket
            {
                ReservationId = reservation.ReservationId,
                UserId = userId,
                EventId = reservation.EventId,
                TicketType = reservation.EventTicket?.TicketType ?? "General",
                QrCode = GenerateQrCode(),
                Amount = reservation.TotalAmount / reservation.Quantity,
                Currency = reservation.Currency,
                Status = TicketStatus.Active,
                IssuedAt = DateTime.UtcNow
            })
            .ToList();

        await _repository.AddTicketsAsync(tickets);

        await _publishEndpoint.Publish(new ReservationConfirmedMessage(
            reservation.ReservationId,
            reservation.EventId,
            reservation.UserId,
            reservation.Quantity,
            reservation.ConfirmedAt ?? DateTime.UtcNow));

        if (payment.Method == PaymentMethod.PayPal)
        {
            await _publishEndpoint.Publish(new PaymentSucceededMessage(
                payment.PaymentId,
                reservation.ReservationId,
                userId,
                payment.Amount,
                payment.Currency,
                payment.TransactionId!,
                payment.PaidAt ?? DateTime.UtcNow));

            await PublishReservationPaidNotificationAsync(
                reservation,
                payment.PaidAt ?? DateTime.UtcNow);
        }
        else if (payment.Method == PaymentMethod.Cash)
        {
            await PublishReservationCashPendingNotificationAsync(
                reservation,
                payment.Amount,
                payment.Currency,
                DateTime.UtcNow);
        }

        foreach (var ticket in tickets)
        {
            await _publishEndpoint.Publish(new TicketPurchasedMessage(
                ticket.TicketId,
                reservation.ReservationId,
                reservation.EventId,
                userId,
                ticket.TicketType,
                ticket.Amount,
                ticket.Currency,
                ticket.IssuedAt));
        }

        _logger.LogInformation(
            "Confirmed reservation {ReservationId} with payment {PaymentId} using {PaymentMethod}",
            reservation.ReservationId,
            payment.PaymentId,
            dto.PaymentMethod);

        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
    }

    private async Task PublishReservationCashPendingNotificationAsync(
    Reservation reservation,
    decimal amount,
    string currency,
    DateTime confirmedAt)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev?.OrganizerId is not int organizerUserId || organizerUserId == reservation.UserId)
            return;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(new[] { reservation.UserId });
        var profile = profiles.FirstOrDefault(x => x.UserId == reservation.UserId);

        await _publishEndpoint.Publish(new EventReservationCashPendingMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            organizerUserId,
            reservation.UserId,
            ResolveDisplayName(profile, reservation.UserId),
            profile?.ImageUrl,
            reservation.Quantity,
            amount,
            currency,
            reservation.Status.ToString(),
            confirmedAt
        ));
    }

    public async Task<ServiceResult<bool>> CancelReservationAsync(int reservationId, int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<bool>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your reservation.");

        if (!reservation.CanBeCancelled())
            return ServiceResult<bool>.Fail("Reservation cannot be cancelled in its current state.");

        if (reservation.Status == ReservationStatus.Confirmed)
        {
            var payments = await _repository.GetPaymentsByReservationAsync(reservationId);

            var completedPaidPayment = payments
                .OrderByDescending(p => p.PaidAt)
                .FirstOrDefault(p => p.Status == PaymentStatus.Completed && p.Amount > 0);

            if (completedPaidPayment is not null)
            {
                return ServiceResult<bool>.Fail(
                    "Paid confirmed reservations must be refunded, not cancelled.",
                    StatusCodes.Status400BadRequest);
            }
        }

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

    public async Task<ServiceResult<ReservationResponseDto>> RequestRefundAsync(
    int reservationId,
    RequestRefundDto dto,
    int userId)
    {
        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<ReservationResponseDto>.Forbidden("Not your reservation.");

        if (!reservation.CanRequestRefund())
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "This reservation cannot request a refund.",
                StatusCodes.Status409Conflict);
        }

        var payments = await _repository.GetPaymentsByReservationAsync(reservationId);

        var payment = payments
            .OrderByDescending(p => p.PaidAt)
            .FirstOrDefault(p =>
                p.Status == PaymentStatus.Completed &&
                p.Method == PaymentMethod.PayPal);

        if (payment is null)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "No completed PayPal payment was found for this reservation.",
                StatusCodes.Status400BadRequest);
        }

        if (payment.Amount <= 0)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Free reservations cannot request PayPal refunds.",
                StatusCodes.Status400BadRequest);
        }

        reservation.RequestRefund(dto.Reason);
        await _repository.UpdateReservationAsync(reservation);

        _logger.LogInformation(
            "Refund requested for reservation {ReservationId} by user {UserId}",
            reservation.ReservationId,
            userId);

        await PublishRefundRequestedNotificationAsync(reservation);

        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
    }

    public async Task<ServiceResult<ReservationResponseDto>> ApproveRefundAsync(
    int eventId,
    int reservationId,
    ApproveRefundDto dto,
    int organizerUserId,
    string organizerRole)
    {
        if (!string.Equals(organizerRole, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            return ServiceResult<ReservationResponseDto>.Forbidden(
                "Only admins can approve refunds.");
        }

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            organizerUserId,
            organizerRole);

        if (!allowed)
        {
            return ServiceResult<ReservationResponseDto>.Forbidden(
                "You are not allowed to approve refunds for this event.");
        }

        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null || reservation.EventId != eventId)
        {
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");
        }

        if (!reservation.CanApproveRefund())
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Only pending refund requests can be approved.",
                StatusCodes.Status409Conflict);
        }

        var payments = await _repository.GetPaymentsByReservationAsync(reservationId);

        var payment = payments
            .OrderByDescending(p => p.PaidAt)
            .FirstOrDefault(p =>
                p.Status == PaymentStatus.Completed &&
                p.Method == PaymentMethod.PayPal);

        if (payment is null)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "No completed PayPal payment was found for this reservation.",
                StatusCodes.Status400BadRequest);
        }

        var providerPaymentId = payment.ProviderPaymentId?.Trim();
        if (string.IsNullOrWhiteSpace(providerPaymentId))
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "PayPal capture ID is missing for this reservation.",
                StatusCodes.Status400BadRequest);
        }

        if (payment.Amount <= 0)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Free reservations cannot be refunded through PayPal.",
                StatusCodes.Status400BadRequest);
        }

        if (dto.Amount.HasValue && dto.Amount.Value != payment.Amount)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Partial refunds are not supported yet.",
                StatusCodes.Status400BadRequest);
        }

        var now = DateTime.UtcNow;

        reservation.MarkRefundProcessing(organizerUserId, dto.DecisionReason);
        await _repository.UpdateReservationAsync(reservation);

        var refundResult = await _payPalService.RefundCaptureAsync(
            providerPaymentId,
            null,
            payment.Currency,
            reservation.RefundReason);

        if (!refundResult.Success || refundResult.Data is null)
        {
            reservation.MarkRefundFailed(
                organizerUserId,
                refundResult.Error ?? dto.DecisionReason);

            await _repository.UpdateReservationAsync(reservation);

            return ServiceResult<ReservationResponseDto>.Fail(
                refundResult.Error ?? "Failed to refund PayPal capture.",
                refundResult.StatusCode);
        }

        payment.Refund(refundResult.Data.RefundId);
        await _repository.UpdatePaymentDetailAsync(payment);

        var tickets = await _repository.GetTicketsByReservationAsync(reservationId);
        foreach (var ticket in tickets.Where(t => t.CanBeCancelled()))
        {
            ticket.Cancel();
            await _repository.UpdateTicketAsync(ticket);

            await _publishEndpoint.Publish(new TicketCancelledMessage(
                ticket.TicketId,
                reservation.EventId,
                reservation.UserId,
                "Reservation refunded",
                now));
        }

        if (reservation.EventTicketId.HasValue)
        {
            var eventTicket = await _repository.GetEventTicketByIdAsync(reservation.EventTicketId.Value);
            if (eventTicket is not null)
            {
                eventTicket.Release(reservation.Quantity);
                await _repository.UpdateEventTicketAsync(eventTicket);
            }
        }

        reservation.MarkRefundCompleted(organizerUserId, dto.DecisionReason);
        await _repository.UpdateReservationAsync(reservation);

        await PublishRefundApprovedNotificationAsync(reservation, payment);

        _logger.LogInformation(
            "Refund approved for reservation {ReservationId} by organizer {OrganizerUserId} with refund {RefundId}",
            reservation.ReservationId,
            organizerUserId,
            refundResult.Data.RefundId);

        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
    }

    public async Task<ServiceResult<ReservationResponseDto>> RejectRefundAsync(
    int eventId,
    int reservationId,
    RejectRefundDto dto,
    int organizerUserId,
    string organizerRole)
    {
        if (!string.Equals(organizerRole, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            return ServiceResult<ReservationResponseDto>.Forbidden(
                "Only admins can reject refunds.");
        }

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            organizerUserId,
            organizerRole);

        if (!allowed)
        {
            return ServiceResult<ReservationResponseDto>.Forbidden(
                "You are not allowed to reject refunds for this event.");
        }

        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null || reservation.EventId != eventId)
        {
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");
        }

        if (reservation.RefundRequestStatus != RefundRequestStatus.Pending)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Only pending refund requests can be rejected.",
                StatusCodes.Status409Conflict);
        }

        reservation.MarkRefundRejected(organizerUserId, dto.DecisionReason);
        await _repository.UpdateReservationAsync(reservation);

        await PublishRefundRejectedNotificationAsync(reservation);

        _logger.LogInformation(
            "Refund rejected for reservation {ReservationId} by organizer {OrganizerUserId}",
            reservation.ReservationId,
            organizerUserId);

        return ServiceResult<ReservationResponseDto>.Ok(MapToReservationResponse(reservation));
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

        var payment = ticket.Reservation?.PaymentDetails
            ?.OrderByDescending(x => x.PaymentId)
            .FirstOrDefault();

        var paymentMethod = payment?.Method.ToString();
        var paymentStatus = payment?.Status.ToString();

        string? paymentMessage = payment switch
        {
            null => null,
            { Method: PaymentMethod.Cash, Status: PaymentStatus.Pending } =>
                $"Cash payment is still due at the event venue ({payment.Amount:0.##} {payment.Currency}).",
            { Method: PaymentMethod.Cash, Status: PaymentStatus.Completed } =>
                $"Cash payment has already been collected ({payment.Amount:0.##} {payment.Currency}).",
            { Method: PaymentMethod.PayPal, Status: PaymentStatus.Completed } =>
                $"PayPal payment completed ({payment.Amount:0.##} {payment.Currency}).",
            _ =>
                $"Payment status: {payment?.Status} via {payment?.Method}."
        };

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
            ScannedAt = DateTime.UtcNow,
            PaymentMethod = paymentMethod,
            PaymentStatus = paymentStatus,
            PaymentMessage = paymentMessage
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

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            requesterId,
            requesterRole);

        if (!allowed)
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

    public async Task<ServiceResult<bool>> RemoveAttendeeReservationAsync(
        int eventId,
        int reservationId,
        int requesterId,
        string requesterRole)
    {
        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            requesterId,
            requesterRole);

        if (!allowed)
        {
            return ServiceResult<bool>.Forbidden(
                "You are not allowed to remove attendees from this event.");
        }

        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null || reservation.EventId != eventId)
            return ServiceResult<bool>.NotFound("Reservation not found.");

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
                reservation.UserId,
                "Removed by organizer",
                DateTime.UtcNow));
        }

        reservation.Cancel();
        await _repository.UpdateReservationAsync(reservation);

        await _publishEndpoint.Publish(new ReservationCancelledIntegrationMessage(
            reservation.ReservationId,
            reservation.EventId,
            reservation.UserId,
            DateTime.UtcNow));

        await PublishAttendeeRemovedNotificationAsync(reservation);

        return ServiceResult<bool>.Ok(true);
    }

    private async Task PublishRefundRequestedNotificationAsync(Reservation reservation)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev?.OrganizerId is not int organizerUserId || organizerUserId == reservation.UserId)
            return;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(new[] { reservation.UserId });
        var profile = profiles.FirstOrDefault(x => x.UserId == reservation.UserId);

        await _publishEndpoint.Publish(new EventRefundRequestedMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            organizerUserId,
            reservation.UserId,
            ResolveDisplayName(profile, reservation.UserId),
            profile?.ImageUrl,
            reservation.Quantity,
            reservation.TotalAmount,
            reservation.Currency,
            reservation.RefundReason,
            reservation.RefundRequestedAt ?? DateTime.UtcNow));
    }

    private async Task PublishRefundApprovedNotificationAsync(
        Reservation reservation,
        PaymentDetail payment)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev is null)
            return;

        await _publishEndpoint.Publish(new ReservationRefundApprovedMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            reservation.UserId,
            reservation.Quantity,
            payment.Amount,
            payment.Currency,
            payment.RefundTransactionId,
            reservation.RefundDecisionReason,
            reservation.RefundReviewedAt ?? DateTime.UtcNow));
    }

    private async Task PublishRefundRejectedNotificationAsync(Reservation reservation)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev is null)
            return;

        await _publishEndpoint.Publish(new ReservationRefundRejectedMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            reservation.UserId,
            reservation.RefundDecisionReason,
            reservation.RefundReviewedAt ?? DateTime.UtcNow));
    }

    private async Task PublishAttendeeRemovedNotificationAsync(Reservation reservation)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev is null)
            return;

        await _publishEndpoint.Publish(new ReservationRemovedByOrganizerMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            reservation.UserId,
            reservation.Quantity,
            DateTime.UtcNow));
    }

    public async Task<ServiceResult<EventReservationSummaryResponseDto>> GetEventReservationSummaryAsync(
        int eventId,
        int requesterId,
        string requesterRole)
    {
        if (eventId <= 0)
            return ServiceResult<EventReservationSummaryResponseDto>.Fail("Invalid event id.", 400);

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            requesterId,
            requesterRole);

        if (!allowed)
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

    public async Task<ServiceResult<ReservationResponseDto>> MarkCashCollectedAsync(
    int eventId,
    int reservationId,
    int organizerUserId,
    string organizerRole)
    {
        if (eventId <= 0)
            return ServiceResult<ReservationResponseDto>.Fail("Invalid event id.", StatusCodes.Status400BadRequest);

        var allowed = await _eventAuthorizationService.CanManageEventAsync(
            eventId,
            organizerUserId,
            organizerRole);

        if (!allowed)
        {
            return ServiceResult<ReservationResponseDto>.Forbidden(
                "You are not allowed to collect cash for this event.");
        }

        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null || reservation.EventId != eventId)
        {
            return ServiceResult<ReservationResponseDto>.NotFound("Reservation not found.");
        }

        if (reservation.Status != ReservationStatus.Confirmed)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Only confirmed reservations can be marked as cash collected.",
                StatusCodes.Status409Conflict);
        }

        var payments = await _repository.GetPaymentsByReservationAsync(reservationId);

        var cashPayment = payments
            .OrderByDescending(p => p.PaymentId)
            .FirstOrDefault(p => p.Method == PaymentMethod.Cash);

        if (cashPayment is null)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "No cash payment record was found for this reservation.",
                StatusCodes.Status400BadRequest);
        }

        if (cashPayment.Status == PaymentStatus.Completed)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                "Cash payment has already been collected.",
                StatusCodes.Status409Conflict);
        }

        if (cashPayment.Status != PaymentStatus.Pending)
        {
            return ServiceResult<ReservationResponseDto>.Fail(
                $"Cash payment cannot be collected from status {cashPayment.Status}.",
                StatusCodes.Status409Conflict);
        }

        cashPayment.Status = PaymentStatus.Completed;
        cashPayment.PaidAt = DateTime.UtcNow;

        await _repository.UpdatePaymentDetailAsync(cashPayment);

        await PublishReservationPaidNotificationAsync(
            reservation,
            cashPayment.PaidAt ?? DateTime.UtcNow);

        _logger.LogInformation(
            "Collected cash for reservation {ReservationId} by organizer {OrganizerUserId}. PaymentId={PaymentId}",
            reservationId,
            organizerUserId,
            cashPayment.PaymentId);

        return ServiceResult<ReservationResponseDto>.Ok(
            MapToReservationResponse(reservation));
    }

    public async Task<ServiceResult<bool>> AttachPendingPayPalOrderAsync(
    int reservationId,
    int userId,
    string providerOrderId)
    {
        if (string.IsNullOrWhiteSpace(providerOrderId))
        {
            return ServiceResult<bool>.Fail(
                "Provider order ID is required.",
                StatusCodes.Status400BadRequest);
        }

        var reservation = await _repository.GetReservationByIdAsync(reservationId);
        if (reservation is null)
            return ServiceResult<bool>.NotFound("Reservation not found.");

        if (reservation.UserId != userId)
            return ServiceResult<bool>.Forbidden("Not your reservation.");

        if (!reservation.CanBeConfirmed())
        {
            return ServiceResult<bool>.Fail(
                reservation.IsExpired() ? "Reservation has expired." : "Reservation is no longer pending.",
                StatusCodes.Status409Conflict);
        }

        reservation.AttachPendingPayment(providerOrderId.Trim(), PaymentMethod.PayPal);
        await _repository.UpdateReservationAsync(reservation);

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
        PendingProviderOrderId = r.PendingProviderOrderId,
        Notes = r.Notes,
        Tickets = r.Tickets?.Select(MapToTicketResponse).ToList() ?? [],
        RefundRequestStatus = r.RefundRequestStatus.ToString(),
        RefundReason = r.RefundReason,
        RefundRequestedAt = r.RefundRequestedAt,
        RefundReviewedAt = r.RefundReviewedAt,
        RefundReviewedByUserId = r.RefundReviewedByUserId,
        RefundDecisionReason = r.RefundDecisionReason,
    };

    private static string ResolveDisplayName(PublicUserProfileDto? profile, int userId)
    {
        if (!string.IsNullOrWhiteSpace(profile?.Username))
            return profile.Username;

        return $"User {userId}";
    }

    private async Task PublishReservationCreatedNotificationAsync(Reservation reservation, DateTime reservedAt)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev?.OrganizerId is not int organizerUserId || organizerUserId == reservation.UserId)
            return;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(new[] { reservation.UserId });
        var profile = profiles.FirstOrDefault(x => x.UserId == reservation.UserId);

        await _publishEndpoint.Publish(new EventReservationCreatedMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            organizerUserId,
            reservation.UserId,
            ResolveDisplayName(profile, reservation.UserId),
            profile?.ImageUrl,
            reservation.Quantity,
            reservation.TotalAmount,
            reservation.Currency,
            reservation.Status.ToString(),
            reservedAt
        ));
    }


    private async Task PublishReservationPaidNotificationAsync(Reservation reservation, DateTime paidAt)
    {
        var ev = await _eventDirectoryClient.GetEventAsync(reservation.EventId);
        if (ev?.OrganizerId is not int organizerUserId || organizerUserId == reservation.UserId)
            return;

        var profiles = await _userDirectoryService.GetPublicProfilesAsync(new[] { reservation.UserId });
        var profile = profiles.FirstOrDefault(x => x.UserId == reservation.UserId);

        await _publishEndpoint.Publish(new EventReservationPaidMessage(
            reservation.ReservationId,
            reservation.EventId,
            ev.Title,
            ev.CoverImageUrl,
            organizerUserId,
            reservation.UserId,
            ResolveDisplayName(profile, reservation.UserId),
            profile?.ImageUrl,
            reservation.Quantity,
            reservation.TotalAmount,
            reservation.Currency,
            reservation.Status.ToString(),
            paidAt
        ));
    }

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
        PaidAt = p.PaidAt ?? DateTime.UtcNow
    };

    private static OrganizerReservationResponseDto MapToOrganizerReservationResponse(Reservation r)
    {
        var payment = r.PaymentDetails?
            .OrderByDescending(x => x.PaymentId)
            .FirstOrDefault();

        var issuedTickets = r.Tickets?.ToList() ?? new List<Ticket>();
        var validatedTicket = issuedTickets
            .Where(t => t.UsedAt.HasValue)
            .OrderByDescending(t => t.UsedAt)
            .FirstOrDefault();

        string? paymentMessage = payment switch
        {
            null => null,
            { Method: PaymentMethod.Cash, Status: PaymentStatus.Pending } =>
                $"Cash payment is still due at the event venue: {payment.Amount:0.##} {payment.Currency}.",
            { Method: PaymentMethod.Cash, Status: PaymentStatus.Completed } =>
                $"Cash payment has already been collected: {payment.Amount:0.##} {payment.Currency}.",
            { Method: PaymentMethod.PayPal, Status: PaymentStatus.Completed } =>
                $"PayPal payment completed: {payment.Amount:0.##} {payment.Currency}.",
            _ => $"Payment status: {payment?.Status} via {payment?.Method}."
        };

        var canCollectCash =
            r.Status == ReservationStatus.Confirmed &&
            payment?.Method == PaymentMethod.Cash &&
            payment?.Status == PaymentStatus.Pending;

        return new OrganizerReservationResponseDto
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
            RefundRequestStatus = r.RefundRequestStatus.ToString(),
            RefundReason = r.RefundReason,
            RefundRequestedAt = r.RefundRequestedAt,
            RefundReviewedAt = r.RefundReviewedAt,
            RefundReviewedByUserId = r.RefundReviewedByUserId,
            RefundDecisionReason = r.RefundDecisionReason,

            PaymentMethod = payment?.Method.ToString(),
            PaymentStatus = payment?.Status.ToString(),
            PaymentMessage = paymentMessage,
            HasIssuedTickets = issuedTickets.Count > 0,
            HasValidatedTicket = validatedTicket is not null,
            ValidatedAt = validatedTicket?.UsedAt,
            CanCollectCash = canCollectCash
        };
    }
}