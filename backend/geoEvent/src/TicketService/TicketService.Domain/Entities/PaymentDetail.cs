using TicketService.Domain.Enums;
using TicketService.Domain.Exceptions;

namespace TicketService.Domain.Entities;

public class PaymentDetail
{
    public int PaymentId { get; private set; }
    public DateTime? PaidAt { get; private set; }
    public int? ReservationId { get; private set; }
    public int? UserId { get; private set; }
    public PaymentStatus Status { get; private set; } = PaymentStatus.Pending;
    public PaymentMethod Method { get; private set; }
    public decimal Amount { get; private set; }
    public string Currency { get; private set; } = "BAM";

    public string? ProviderPaymentId { get; private set; }
    public string? ProviderOrderId { get; private set; }
    public string? TransactionId { get; private set; }
    public string? RefundTransactionId { get; private set; }

    public Reservation? Reservation { get; set; }

    private PaymentDetail()
    {
    }

    private PaymentDetail(
        int? reservationId,
        int? userId,
        PaymentMethod method,
        decimal amount,
        string currency,
        string? transactionId = null,
        string? providerOrderId = null)
    {
        if (amount < 0)
            throw new BusinessException("Payment amount cannot be negative.");

        if (string.IsNullOrWhiteSpace(currency))
            throw new BusinessException("Currency is required.");

        ReservationId = reservationId;
        UserId = userId;
        Method = method;
        Amount = amount;
        Currency = currency.Trim().ToUpperInvariant();
        TransactionId = string.IsNullOrWhiteSpace(transactionId) ? null : transactionId.Trim();
        ProviderOrderId = string.IsNullOrWhiteSpace(providerOrderId) ? null : providerOrderId.Trim();
    }

    public static PaymentDetail CreatePendingCash(
        int reservationId,
        int userId,
        decimal amount,
        string currency,
        string transactionId)
    {
        if (string.IsNullOrWhiteSpace(transactionId))
            throw new BusinessException("Transaction ID is required.");

        return new PaymentDetail(
            reservationId,
            userId,
            PaymentMethod.Cash,
            amount,
            currency,
            transactionId: transactionId);
    }

    public static PaymentDetail CreateCompletedPayPal(
        int reservationId,
        int userId,
        decimal amount,
        string currency,
        string providerOrderId,
        string providerPaymentId,
        string transactionId)
    {
        var payment = new PaymentDetail(
            reservationId,
            userId,
            PaymentMethod.PayPal,
            amount,
            currency,
            transactionId: transactionId,
            providerOrderId: providerOrderId);

        payment.Complete(providerPaymentId, transactionId);
        return payment;
    }

    public bool IsSuccessful() => Status == PaymentStatus.Completed;

    public void AttachProviderOrder(string providerOrderId)
    {
        if (string.IsNullOrWhiteSpace(providerOrderId))
            throw new BusinessException("Provider order ID is required.");

        if (Status != PaymentStatus.Pending)
            throw new BusinessException("Provider order can only be attached to a pending payment.");

        ProviderOrderId = providerOrderId.Trim();
    }

    public void Complete(string providerPaymentId, string transactionId)
    {
        if (Status != PaymentStatus.Pending)
            throw new BusinessException("Only pending payments can be completed.");

        if (string.IsNullOrWhiteSpace(providerPaymentId))
            throw new BusinessException("Provider payment ID is required.");

        if (string.IsNullOrWhiteSpace(transactionId))
            throw new BusinessException("Transaction ID is required.");

        ProviderPaymentId = providerPaymentId.Trim();
        TransactionId = transactionId.Trim();
        Status = PaymentStatus.Completed;
        PaidAt = DateTime.UtcNow;
    }

    public void Fail()
    {
        if (Status != PaymentStatus.Pending)
            throw new BusinessException("Only pending payments can fail.");

        Status = PaymentStatus.Failed;
    }

    public void Cancel()
    {
        if (Status != PaymentStatus.Pending)
            throw new BusinessException("Only pending payments can be cancelled.");

        Status = PaymentStatus.Cancelled;
    }

    public void Refund(string refundTransactionId)
    {
        if (Status != PaymentStatus.Completed)
            throw new BusinessException("Only completed payments can be refunded.");

        if (string.IsNullOrWhiteSpace(refundTransactionId))
            throw new BusinessException("Refund transaction ID is required.");

        RefundTransactionId = refundTransactionId.Trim();
        Status = PaymentStatus.Refunded;
    }

    public void CompleteCash(string transactionId)
    {
        if (Status != PaymentStatus.Pending)
            throw new BusinessException("Only pending payments can be completed.");

        if (string.IsNullOrWhiteSpace(transactionId))
            throw new BusinessException("Transaction ID is required.");

        TransactionId = transactionId.Trim();
        Status = PaymentStatus.Completed;
        PaidAt = DateTime.UtcNow;
    }
}