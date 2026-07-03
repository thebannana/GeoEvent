using TicketService.Domain.Enums;

namespace TicketService.Domain.Entities;

public class Reservation
{
    public int ReservationId { get; set; }
    public DateTime ReservedAt { get; set; } = DateTime.UtcNow;
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int? EventTicketId { get; set; }
    public int Quantity { get; set; }
    public decimal TotalAmount { get; set; }
    public string Currency { get; set; } = "BAM";
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime? ExpiredAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string? PaymentReference { get; set; }
    public string? Notes { get; set; }

    public string? PendingProviderOrderId { get; set; }
    public PaymentMethod? PendingPaymentMethod { get; set; }
    public DateTime? PendingPaymentCreatedAt { get; set; }

    public EventTicket? EventTicket { get; set; }
    public ICollection<Ticket> Tickets { get; set; } = [];
    public ICollection<PaymentDetail> PaymentDetails { get; set; } = [];
    public RefundRequestStatus RefundRequestStatus { get; private set; } = RefundRequestStatus.None;
    public string? RefundReason { get; private set; }
    public DateTime? RefundRequestedAt { get; private set; }
    public DateTime? RefundReviewedAt { get; private set; }
    public int? RefundReviewedByUserId { get; private set; }
    public string? RefundDecisionReason { get; private set; }

    public bool IsExpired() =>
        Status == ReservationStatus.Pending && DateTime.UtcNow > ExpiresAt;

    public bool CanBeConfirmed() =>
        Status == ReservationStatus.Pending && !IsExpired();

    public bool CanBeCancelled() =>
        Status == ReservationStatus.Pending ||
        Status == ReservationStatus.Confirmed;

    public void AttachPendingPayment(string providerOrderId, PaymentMethod paymentMethod)
    {
        if (!CanBeConfirmed())
            throw new InvalidOperationException("Reservation cannot accept a pending payment in its current state.");

        if (string.IsNullOrWhiteSpace(providerOrderId))
            throw new ArgumentException("Provider order ID is required.");

        PendingProviderOrderId = providerOrderId;
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
            throw new InvalidOperationException(
                "Reservation cannot be cancelled in its current state.");

        Status = ReservationStatus.Cancelled;
        CancelledAt = DateTime.UtcNow;
        ClearPendingPayment();
    }

    public void Confirm(string paymentReference)
    {
        if (!CanBeConfirmed())
            throw new InvalidOperationException("Reservation cannot be confirmed in its current state.");

        if (string.IsNullOrWhiteSpace(paymentReference))
            throw new ArgumentException("Payment reference is required.");

        Status = ReservationStatus.Confirmed;
        ConfirmedAt = DateTime.UtcNow;
        PaymentReference = paymentReference;
        ClearPendingPayment();
    }

    public void Expire()
    {
        if (Status != ReservationStatus.Pending)
            throw new InvalidOperationException("Only pending reservations can expire.");

        Status = ReservationStatus.Expired;
        ExpiredAt = DateTime.UtcNow;
        ClearPendingPayment();
    }

    public void Refund()
    {
        if (Status != ReservationStatus.Confirmed)
            throw new InvalidOperationException("Only confirmed reservations can be refunded.");

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

    public void RequestRefund(string? reason)
    {
        if (!CanRequestRefund())
            throw new InvalidOperationException("Refund cannot be requested for this reservation.");

        RefundRequestStatus = RefundRequestStatus.Pending;
        RefundReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        RefundRequestedAt = DateTime.UtcNow;
        RefundReviewedAt = null;
        RefundReviewedByUserId = null;
        RefundDecisionReason = null;
    }

    public void MarkRefundApproved(int reviewerUserId, string? decisionReason)
    {
        if (RefundRequestStatus != RefundRequestStatus.Pending)
            throw new InvalidOperationException("Only pending refund requests can be approved.");

        RefundRequestStatus = RefundRequestStatus.Approved;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason)
            ? null
            : decisionReason.Trim();
    }

    public void MarkRefundRejected(int reviewerUserId, string? decisionReason)
    {
        if (RefundRequestStatus != RefundRequestStatus.Pending)
            throw new InvalidOperationException("Only pending refund requests can be rejected.");

        RefundRequestStatus = RefundRequestStatus.Rejected;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason)
            ? null
            : decisionReason.Trim();
    }

    public void MarkRefundProcessing(int reviewerUserId, string? decisionReason)
    {
        if (RefundRequestStatus != RefundRequestStatus.Pending &&
            RefundRequestStatus != RefundRequestStatus.Approved)
        {
            throw new InvalidOperationException("Refund request is not ready for processing.");
        }

        RefundRequestStatus = RefundRequestStatus.Processing;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason)
            ? null
            : decisionReason.Trim();
    }

    public void MarkRefundFailed(int reviewerUserId, string? decisionReason)
    {
        RefundRequestStatus = RefundRequestStatus.Failed;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason)
            ? null
            : decisionReason.Trim();
    }

    public void MarkRefundCompleted(int reviewerUserId, string? decisionReason)
    {
        RefundRequestStatus = RefundRequestStatus.Refunded;
        RefundReviewedAt = DateTime.UtcNow;
        RefundReviewedByUserId = reviewerUserId;
        RefundDecisionReason = string.IsNullOrWhiteSpace(decisionReason)
            ? null
            : decisionReason.Trim();

        Refund();
    }
}