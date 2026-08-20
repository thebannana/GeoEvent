using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;
using TicketService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class ReservationSeeder : ISeeder
{
    private readonly TicketDbContext _dbContext;
    private readonly IReadOnlyList<SeedReservationOptions> _reservations;
    private readonly ILogger<ReservationSeeder> _logger;

    public ReservationSeeder(
        TicketDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<ReservationSeeder> logger)
    {
        _dbContext = dbContext;
        _reservations = options.Value.SeedReservations ?? new List<SeedReservationOptions>();
        _logger = logger;
    }

    public string Name => "reservations";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_reservations.Count == 0)
        {
            _logger.LogWarning("No reservations configured in SeedReservations.");
            return;
        }

        foreach (var seed in _reservations)
        {
            var eventTicketExists = await _dbContext.EventTickets.AnyAsync(
                t => t.TicketId == seed.EventTicketId, cancellationToken);

            if (!eventTicketExists)
            {
                _logger.LogWarning(
                    "Skipping reservation: EventTicketId {EventTicketId} does not exist.",
                    seed.EventTicketId);
                continue;
            }

            if (!Enum.TryParse<ReservationStatus>(seed.Status, true, out var targetStatus))
            {
                _logger.LogWarning(
                    "Skipping reservation: Invalid Status {Status}.",
                    seed.Status);
                continue;
            }

            if (!Enum.TryParse<RefundRequestStatus>(seed.RefundRequestStatus ?? "None", true, out var refundStatus))
            {
                _logger.LogWarning(
                    "Skipping reservation: Invalid RefundRequestStatus {RefundStatus}.",
                    seed.RefundRequestStatus);
                continue;
            }

            var expiresAt = seed.ExpiresAt ?? DateTime.UtcNow.AddMinutes(15);

            var reservation = Reservation.Create(
                seed.EventId,
                seed.UserId,
                seed.EventTicketId,
                seed.Quantity,
                seed.TotalAmount,
                seed.Currency.Trim().ToUpperInvariant(),
                expiresAt,
                string.IsNullOrWhiteSpace(seed.Notes) ? null : seed.Notes.Trim());

            switch (targetStatus)
            {
                case ReservationStatus.Pending:
                    break;

                case ReservationStatus.Confirmed:
                    if (reservation.CanBeConfirmed())
                    {
                        reservation.Confirm(seed.PaymentReference ?? "SEED-REF-" + reservation.ReservationId);
                    }
                    else
                    {
                        _logger.LogWarning(
                            "Reservation {ReservationId} cannot be confirmed (status={Status}, expired={IsExpired}). Skipping Confirm().",
                            reservation.ReservationId,
                            reservation.Status,
                            reservation.IsExpired());
                    }
                    break;

                case ReservationStatus.Cancelled:
                    if (reservation.CanBeCancelled())
                    {
                        reservation.Cancel();
                    }
                    else
                    {
                        _logger.LogWarning(
                            "Reservation {ReservationId} cannot be cancelled (status={Status}). Skipping Cancel().",
                            reservation.ReservationId,
                            reservation.Status);
                    }
                    break;

                case ReservationStatus.Expired:
                    if (reservation.Status == ReservationStatus.Pending)
                    {
                        reservation.Expire();
                    }
                    else
                    {
                        _logger.LogWarning(
                            "Reservation {ReservationId} cannot be expired (status={Status}). Skipping Expire().",
                            reservation.ReservationId,
                            reservation.Status);
                    }
                    break;

                case ReservationStatus.Refunded:
                    if (reservation.CanBeConfirmed())
                    {
                        reservation.Confirm(seed.PaymentReference ?? "SEED-REF-" + reservation.ReservationId);
                    }

                    if (reservation.Status == ReservationStatus.Confirmed)
                    {
                        reservation.Refund();
                    }
                    else
                    {
                        _logger.LogWarning(
                            "Reservation {ReservationId} cannot be refunded (status={Status}). Skipping Refund().",
                            reservation.ReservationId,
                            reservation.Status);
                    }
                    break;

                default:
                    _logger.LogWarning(
                        "Unsupported reservation status {Status} for ReservationId {ReservationId}. Skipping status transition.",
                        targetStatus,
                        reservation.ReservationId);
                    break;
            }

            if (refundStatus != RefundRequestStatus.None && !string.IsNullOrWhiteSpace(seed.RefundReason))
            {
                if (reservation.CanRequestRefund())
                {
                    reservation.RequestRefund(seed.RefundReason.Trim());
                }
                else
                {
                    _logger.LogWarning(
                        "Reservation {ReservationId} cannot request refund (status={Status}, refundStatus={RefundStatus}). Skipping RequestRefund().",
                        reservation.ReservationId,
                        reservation.Status,
                        refundStatus);
                }
            }

            if (seed.RefundReviewedAt.HasValue && seed.RefundReviewedByUserId.HasValue)
            {
                switch (refundStatus)
                {
                    case RefundRequestStatus.Approved:
                        if (reservation.CanApproveRefund())
                        {
                            reservation.MarkRefundApproved(
                                seed.RefundReviewedByUserId.Value,
                                string.IsNullOrWhiteSpace(seed.RefundDecisionReason) ? null : seed.RefundDecisionReason.Trim(),
                                string.IsNullOrWhiteSpace(seed.RefundModeratorAction) ? null : seed.RefundModeratorAction.Trim());
                        }
                        else
                        {
                            _logger.LogWarning(
                                "Reservation {ReservationId} cannot approve refund (status={Status}, refundStatus={RefundStatus}). Skipping MarkRefundApproved().",
                                reservation.ReservationId,
                                reservation.Status,
                                refundStatus);
                        }
                        break;

                    case RefundRequestStatus.Rejected:
                        if (reservation.CanRejectRefund())
                        {
                            reservation.MarkRefundRejected(
                                seed.RefundReviewedByUserId.Value,
                                string.IsNullOrWhiteSpace(seed.RefundDecisionReason) ? null : seed.RefundDecisionReason.Trim(),
                                string.IsNullOrWhiteSpace(seed.RefundModeratorAction) ? null : seed.RefundModeratorAction.Trim());
                        }
                        else
                        {
                            _logger.LogWarning(
                                "Reservation {ReservationId} cannot reject refund (status={Status}, refundStatus={RefundStatus}). Skipping MarkRefundRejected().",
                                reservation.ReservationId,
                                reservation.Status,
                                refundStatus);
                        }
                        break;

                    case RefundRequestStatus.Processing:
                        if (reservation.CanMarkRefundProcessing())
                        {
                            reservation.MarkRefundProcessing(
                                seed.RefundReviewedByUserId.Value,
                                string.IsNullOrWhiteSpace(seed.RefundDecisionReason) ? null : seed.RefundDecisionReason.Trim(),
                                string.IsNullOrWhiteSpace(seed.RefundModeratorAction) ? null : seed.RefundModeratorAction.Trim());
                        }
                        else
                        {
                            _logger.LogWarning(
                                "Reservation {ReservationId} cannot mark refund processing (status={Status}, refundStatus={RefundStatus}). Skipping MarkRefundProcessing().",
                                reservation.ReservationId,
                                reservation.Status,
                                refundStatus);
                        }
                        break;

                    case RefundRequestStatus.Refunded:
                        break;

                    default:
                        _logger.LogWarning(
                            "Unhandled refund status {RefundStatus} for ReservationId {ReservationId}. Skipping refund review actions.",
                            refundStatus,
                            reservation.ReservationId);
                        break;
                }
            }

            await _dbContext.Reservations.AddAsync(reservation, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Reservation created: ReservationId {ReservationId}, EventId {EventId}, UserId {UserId}, Status {Status}",
                reservation.ReservationId,
                reservation.EventId,
                reservation.UserId,
                reservation.Status);
        }
    }
}