using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;
using TicketService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class TicketSeeder : ISeeder
{
    private readonly TicketDbContext _dbContext;
    private readonly IReadOnlyList<SeedTicketOptions> _tickets;
    private readonly ILogger<TicketSeeder> _logger;

    public TicketSeeder(
        TicketDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<TicketSeeder> logger)
    {
        _dbContext = dbContext;
        _tickets = options.Value.SeedTickets ?? new List<SeedTicketOptions>();
        _logger = logger;
    }

    public string Name => "tickets";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_tickets.Count == 0)
        {
            _logger.LogWarning("No tickets configured in SeedTickets.");
            return;
        }

        foreach (var seed in _tickets)
        {
            var reservationExists = await _dbContext.Reservations.AnyAsync(r => r.ReservationId == seed.ReservationId, cancellationToken);
            if (!reservationExists)
            {
                _logger.LogWarning("Skipping ticket: ReservationId {ReservationId} does not exist.", seed.ReservationId);
                continue;
            }

            if (!Enum.TryParse<TicketStatus>(seed.Status, true, out var status))
            {
                _logger.LogWarning("Skipping ticket: Invalid Status {Status}.", seed.Status);
                continue;
            }

            var existingByQrCode = await _dbContext.IssuedTickets
                .AnyAsync(t => t.QrCode == seed.QrCode, cancellationToken);

            if (existingByQrCode)
            {
                _logger.LogWarning("Skipping ticket: QrCode {QrCode} already exists.", seed.QrCode);
                continue;
            }

            var qrCode = string.IsNullOrWhiteSpace(seed.QrCode)
                ? "SEED-QR-" + Guid.NewGuid().ToString("N")[..8].ToUpper()
                : seed.QrCode.Trim();

            var ticket = Ticket.Issue(
                seed.ReservationId,
                seed.UserId,
                seed.EventId,
                seed.TicketType.Trim(),
                qrCode,
                seed.Amount,
                seed.Currency.Trim().ToUpperInvariant(),
                string.IsNullOrWhiteSpace(seed.SeatNumber) ? null : seed.SeatNumber.Trim(),
                string.IsNullOrWhiteSpace(seed.Section) ? null : seed.Section.Trim());

            if (status == TicketStatus.Used)
            {
                if (ticket.CanBeUsed())
                {
                    ticket.MarkAsUsed();
                }
            }
            else if (status == TicketStatus.Cancelled)
            {
                if (ticket.CanBeCancelled())
                {
                    ticket.Cancel();
                }
            }
            else if (status == TicketStatus.Expired || status == TicketStatus.Refunded)
            {
                if (status == TicketStatus.Expired)
                {
                    ticket.Expire();
                }
                else if (status == TicketStatus.Refunded)
                {
                    ticket.Refund();
                }
            }

            await _dbContext.IssuedTickets.AddAsync(ticket, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Ticket created: TicketId {TicketId}, ReservationId {ReservationId}, EventId {EventId}, Status {Status}",
                ticket.TicketId, ticket.ReservationId, ticket.EventId, ticket.Status);
        }
    }
}