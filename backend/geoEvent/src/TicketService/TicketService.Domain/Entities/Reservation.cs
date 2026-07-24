using TicketService.Domain.Enums;
using TicketService.Domain.Exceptions;

namespace TicketService.Domain.Entities;

public class Reservation
{
    public int ReservationId { get; private set; }
    public DateTime ReservedAt { get; private set; }
    public int EventId { get; private set; }
    public int UserId { get; private set; }
    public int? EventTicketId { get; private set; }
    public int Quantity { get; private set; }
    public decimal TotalAmount { get; private set; }
    public string Currency { get; private set; } = "BAM";
    public ReservationStatus Status { get; private set; } = ReservationStatus.Pending;
    public DateTime CreatedAt { get; private set; }
    public DateTime? ConfirmedAt { get; private set; }
    public DateTime? CancelledAt { get; private set; }
    public DateTime? ExpiredAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public string? PaymentReference { get; private set; }
    public string? Notes { get; private set; }

    public string? PendingProviderOrderId { get; private set; }
    public PaymentMethod? PendingPaymentMethod { get; private set; }
    public DateTime? PendingPaymentCreatedAt { get; private set; }

    public EventTicket? EventTicket { get; set; }
    public ICollection<Ticket> Tickets { get; private set; } = [];
    public ICollection<PaymentDetail> PaymentDetails { get; private set; } = [];

    public RefundRequestStatus RefundRequestStatus { get; private set; } = RefundRequestStatus.None;
    public string? RefundReason { get; private set; }
    public DateTime? RefundRequestedAt { get; private set; }
    public DateTime? RefundReviewedAt { get; private set; }
    public int? RefundReviewedByUserId { get; private set; }
    public string? RefundDecisionReason { get; private set; }
    public string? RefundModeratorAction { get; private set; }

    private Reservation() { }

    public static Reservation Create(
        int eventId,
        int userId,
        int eventTicketId,
        int quantity,
        decimal totalAmount,
        string currency,
        DateTime expiresAt,
        string? notes)
    {
        if (eventId <= 0)
            throw new BusinessException("Event ID is required.");

        if (userId <= 0)
            throw new BusinessException("User ID is required.");

        if (eventTicketId <= 0)
            throw new BusinessException("Event ticket ID is required.");

        if (quantity <= 0)
            throw new BusinessException("Quantity must be greater than zero.");

        if (totalAmount < 0)
            throw new BusinessException("Total amount cannot be negative.");

        if (string.IsNullOrWhiteSpace(currency))
            throw new BusinessException("Currency is required.");

        var now = DateTime.UtcNow;

        return new Reservation
        {
            ReservedAt = now,
            EventId = eventId,
            UserId = userId,
            EventTicketId = eventTicketId,
            Quantity = quantity,
            TotalAmount = totalAmount,
            Currency = currency.Trim().ToUpperInvariant(),
            Status = ReservationStatus.Pending,
            CreatedAt = now,
            ExpiresAt = expiresAt,
            Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim()
        };
    }

    public bool IsExpired() =>
        Status == ReservationStatus.Pending && DateTime.UtcNow > ExpiresAt;

    public bool CanBeConfirmed() =>
        Status == ReservationStatus.Pending && !IsExpired();

    public bool CanBeCancelled() =>
        Status == ReservationStatus.Pending || Status == ReservationStatus.Confirmed;

    public void AttachPendingPayment(string providerOrderId, PaymentMethod paymentMethod)
    {
        if (!CanBeConfirmed())
            throw new BusinessException("Reservation cannot accept a pending payment in its current state.");

        if (string.IsNullOrWhiteSpace(providerOrderId))
            throw new BusinessException("Provider order ID is required.");

        PendingProviderOrderId = providerOrderId.Trim();
        PendingPaymentMethod = paymentMethod;
        PendingPaymentCreatedAt = DateTime.UtcNow;
    }

    public void ClearPendingPayment()
    {
        PendingProviderOrderId = null;
        PendingPaymentMethod = null;
        PendingPaymentCreatedAt = null;
    }

    public void Cancel()
    {
        if (!CanBeCancelled())
            throw new BusinessException("Reservation cannot be cancelled in its current state.");

        Status = ReservationStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
        ClearPendingPayment();
    }

    public void Confirm(string paymentReference)
    {
        if (!CanBeConfirmed())
            throw new BusinessException("Reservation cannot be confirmed in its current state.");

        if (string.IsNullOrWhiteSpace(paymentReference))
            throw new BusinessException("Payment reference is required.");

        Status = ReservationStatus.Confirmed;
        ConfirmedAt = DateTime.UtcNow;
        PaymentReference = paymentReference.Trim();
        ClearPendingPayment();
    }

    public void Expire()
    {
        if (Status != ReservationStatus.Pending)
            throw new BusinessException("Only pending reservations can expire.");

        Status = ReservationStatus.Expired;
        ExpiredAt = DateTime.UtcNow;
        ClearPendingPayment();
    }

    public void Refund()
    {
        if (Status != ReservationStatus.Confirmed)
            throw new BusinessException("Only confirmed reservations can be refunded.");

        Status = ReservationStatus.Refunded;
        CancelledAt = DateTime.UtcNow;
        ClearPendingPayment();
    }

    public bool CanRequestRefund()
    {
        return Status == ReservationStatus.Confirmed &&
               TotalAmount > 0 &&
               RefundRequestStatus != RefundRequestStatus.Pending &&
               RefundRequestStatus != RefundRequestStatus.Approved &&
               RefundRequestStatus != RefundRequestStatus.Processing &&
               RefundRequestStatus != RefundRequestStatus.Refunded;
    }

    public bool CanApproveRefund()
    {
        return RefundRequestStatus == RefundRequestStatus.Pending &&
               Status == ReservationStatus.Confirmed;
    }

    public bool CanRejectRefund()
    {
        return RefundRequestStatus == RefundRequestStatus.Pending &&
               Status == ReservationStatus.Confirmed;
    }

    public bool CanMarkRefundProcessing()
    {
        return (RefundRequestStatus == RefundRequestStatus.Pending ||
                RefundRequestStatus == RefundRequestStatus.Approved) &&
               Status == ReservationStatus.Confirmed;
    }

    public bool CanMarkRefundFailed()
    {
        return RefundRequestStatus == RefundRequestStatus.Processing;
    }

    public bool CanMarkRefundCompleted()
    {
        return (RefundRequestStatus == RefundRequestStatus.Processing ||
                RefundRequestStatus == RefundRequestStatus.Approved) &&
               Status == ReservationStatus.Confirmed;
    }

    public void RequestRefund(string? reason)
    {
        if (!CanRequestRefund())
            throw new BusinessException("Refund cannot be requested for this reservation.");

        RefundRequestStatus = RefundRequestStatus.Pending;
        RefundReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        RefundRequestedAt = DateTime.UtcNow;
        RefundReviewedAt = null;
        RefundReviewedByUserId = null;
        RefundDecisionReason = null;
        RefundModeratorAction = null;
    }

    public void MarkRefundApproved(int reviewerUserId, string? decisionReason, string? moderatorAction)
    {
        if (!CanApproveRefund())
            throw new BusinessException("Only pending refund requests can be approved.");

        if (reviewerUserId <= 0)
            throw new BusinessException("Reviewer user ID is required.");

        RefundRequestStatus = RefundRequestStatus.Approved;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason) ? null : decisionReason.Trim();
        RefundModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void MarkRefundRejected(int reviewerUserId, string? decisionReason, string? moderatorAction)
    {
        if (!CanRejectRefund())
            throw new BusinessException("Only pending refund requests can be rejected.");

        if (reviewerUserId <= 0)
            throw new BusinessException("Reviewer user ID is required.");

        RefundRequestStatus = RefundRequestStatus.Rejected;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason) ? null : decisionReason.Trim();
        RefundModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void MarkRefundProcessing(int reviewerUserId, string? decisionReason, string? moderatorAction)
    {
        if (!CanMarkRefundProcessing())
            throw new BusinessException("Refund request is not ready for processing.");

        if (reviewerUserId <= 0)
            throw new BusinessException("Reviewer user ID is required.");

        RefundRequestStatus = RefundRequestStatus.Processing;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason) ? null : decisionReason.Trim();
        RefundModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void MarkRefundFailed(int reviewerUserId, string? decisionReason, string? moderatorAction)
    {
        if (!CanMarkRefundFailed())
            throw new BusinessException("Only processing refund requests can fail.");

        if (reviewerUserId <= 0)
            throw new BusinessException("Reviewer user ID is required.");

        RefundRequestStatus = RefundRequestStatus.Failed;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason) ? null : decisionReason.Trim();
        RefundModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();
    }

    public void MarkRefundCompleted(int reviewerUserId, string? decisionReason, string? moderatorAction)
    {
        if (!CanMarkRefundCompleted())
            throw new BusinessException("Refund request is not ready to be completed.");

        if (reviewerUserId <= 0)
            throw new BusinessException("Reviewer user ID is required.");

        RefundRequestStatus = RefundRequestStatus.Refunded;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason) ? null : decisionReason.Trim();
        RefundModeratorAction = string.IsNullOrWhiteSpace(moderatorAction) ? null : moderatorAction.Trim();

        Refund();
    }
}