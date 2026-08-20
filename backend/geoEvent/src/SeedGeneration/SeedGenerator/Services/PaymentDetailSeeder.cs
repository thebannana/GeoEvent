using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;
using TicketService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class PaymentDetailSeeder : ISeeder
{
    private readonly TicketDbContext _dbContext;
    private readonly IReadOnlyList<SeedPaymentDetailOptions> _payments;
    private readonly ILogger<PaymentDetailSeeder> _logger;

    public PaymentDetailSeeder(
        TicketDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<PaymentDetailSeeder> logger)
    {
        _dbContext = dbContext;
        _payments = options.Value.SeedPaymentDetails ?? new List<SeedPaymentDetailOptions>();
        _logger = logger;
    }

    public string Name => "paymentdetails";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_payments.Count == 0)
        {
            _logger.LogWarning("No payment details configured in SeedPaymentDetails.");
            return;
        }

        foreach (var seed in _payments)
        {
            var reservationExists = await _dbContext.Reservations.AnyAsync(r => r.ReservationId == seed.ReservationId, cancellationToken);
            if (!reservationExists)
            {
                _logger.LogWarning("Skipping payment detail: ReservationId {ReservationId} does not exist.", seed.ReservationId);
                continue;
            }

            if (!Enum.TryParse<PaymentMethod>(seed.Method, true, out var method))
            {
                _logger.LogWarning("Skipping payment detail: Invalid Method {Method}.", seed.Method);
                continue;
            }

            if (!Enum.TryParse<PaymentStatus>(seed.Status, true, out var status))
            {
                _logger.LogWarning("Skipping payment detail: Invalid Status {Status}.", seed.Status);
                continue;
            }

            var existingByTransactionId = await _dbContext.PaymentDetails
                .AnyAsync(p => p.TransactionId == seed.TransactionId, cancellationToken);

            if (existingByTransactionId)
            {
                _logger.LogWarning("Skipping payment detail: TransactionId {TransactionId} already exists.", seed.TransactionId);
                continue;
            }

            PaymentDetail payment;

            if (method == PaymentMethod.Cash && status == PaymentStatus.Completed)
            {
                var transactionId = string.IsNullOrWhiteSpace(seed.TransactionId)
                    ? "SEED-CASH-" + seed.ReservationId
                    : seed.TransactionId.Trim();

                payment = PaymentDetail.CreatePendingCash(
                    seed.ReservationId,
                    seed.UserId,
                    seed.Amount,
                    seed.Currency.Trim().ToUpperInvariant(),
                    transactionId);

                payment.CompleteCash(transactionId);
            }
            else if (method == PaymentMethod.PayPal && status == PaymentStatus.Completed)
            {
                var providerOrderId = string.IsNullOrWhiteSpace(seed.ProviderOrderId)
                    ? "SEED-PP-ORDER-" + seed.ReservationId
                    : seed.ProviderOrderId.Trim();

                var providerPaymentId = string.IsNullOrWhiteSpace(seed.ProviderPaymentId)
                    ? "SEED-PP-CAPTURE-" + seed.ReservationId
                    : seed.ProviderPaymentId.Trim();

                var transactionId = string.IsNullOrWhiteSpace(seed.TransactionId)
                    ? providerPaymentId
                    : seed.TransactionId.Trim();

                payment = PaymentDetail.CreateCompletedPayPal(
                    seed.ReservationId,
                    seed.UserId,
                    seed.Amount,
                    seed.Currency.Trim().ToUpperInvariant(),
                    providerOrderId,
                    providerPaymentId,
                    transactionId);

                if (status == PaymentStatus.Refunded && !string.IsNullOrWhiteSpace(seed.RefundTransactionId))
                {
                    payment.Refund(seed.RefundTransactionId.Trim());
                }
            }
            else
            {

                if (method == PaymentMethod.Cash)
                {
                    var transactionId = string.IsNullOrWhiteSpace(seed.TransactionId)
                        ? "SEED-CASH-" + seed.ReservationId
                        : seed.TransactionId.Trim();

                    payment = PaymentDetail.CreatePendingCash(
                        seed.ReservationId,
                        seed.UserId,
                        seed.Amount,
                        seed.Currency.Trim().ToUpperInvariant(),
                        transactionId);

                    if (status == PaymentStatus.Completed)
                    {
                        payment.CompleteCash(transactionId);
                    }
                    else if (status == PaymentStatus.Failed)
                    {
                        payment.Fail();
                    }
                    else if (status == PaymentStatus.Cancelled)
                    {
                        payment.Cancel();
                    }
                    else if (status == PaymentStatus.Refunded && !string.IsNullOrWhiteSpace(seed.RefundTransactionId))
                    {
                        payment.CompleteCash(transactionId);
                        payment.Refund(seed.RefundTransactionId.Trim());
                    }
                }
                else if (method == PaymentMethod.PayPal)
                {
                    var providerOrderId = string.IsNullOrWhiteSpace(seed.ProviderOrderId)
                        ? "SEED-PP-ORDER-" + seed.ReservationId
                        : seed.ProviderOrderId.Trim();

                    var providerPaymentId = string.IsNullOrWhiteSpace(seed.ProviderPaymentId)
                        ? "SEED-PP-CAPTURE-" + seed.ReservationId
                        : seed.ProviderPaymentId.Trim();

                    var transactionId = string.IsNullOrWhiteSpace(seed.TransactionId)
                        ? providerPaymentId
                        : seed.TransactionId.Trim();

                    payment = PaymentDetail.CreateCompletedPayPal(
                        seed.ReservationId,
                        seed.UserId,
                        seed.Amount,
                        seed.Currency.Trim().ToUpperInvariant(),
                        providerOrderId,
                        providerPaymentId,
                        transactionId);

                    if (status == PaymentStatus.Refunded && !string.IsNullOrWhiteSpace(seed.RefundTransactionId))
                    {
                        payment.Refund(seed.RefundTransactionId.Trim());
                    }
                    else if (status == PaymentStatus.Failed)
                    {
                        payment.Fail();
                    }
                    else if (status == PaymentStatus.Cancelled)
                    {
                        payment.Cancel();
                    }
                }
                else
                {
                    _logger.LogWarning("Skipping payment detail: Unsupported method {Method}.", method);
                    continue;
                }
            }

            await _dbContext.PaymentDetails.AddAsync(payment, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Payment detail created: PaymentId {PaymentId}, ReservationId {ReservationId}, Method {Method}, Status {Status}",
                payment.PaymentId, payment.ReservationId, payment.Method, payment.Status);
        }
    }
}