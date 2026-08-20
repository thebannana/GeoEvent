using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using TicketService.Domain.Entities;
using TicketService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class EventTicketSeeder : ISeeder
{
    private readonly TicketDbContext _dbContext;
    private readonly IReadOnlyList<SeedEventTicketOptions> _tickets;
    private readonly ILogger<EventTicketSeeder> _logger;

    public EventTicketSeeder(
        TicketDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<EventTicketSeeder> logger)
    {
        _dbContext = dbContext;
        _tickets = options.Value.SeedEventTickets ?? new List<SeedEventTicketOptions>();
        _logger = logger;
    }

    public string Name => "eventtickets";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_tickets.Count == 0)
        {
            _logger.LogWarning("No event tickets configured in SeedEventTickets.");
            return;
        }

        foreach (var seed in _tickets)
        {
            var existing = await _dbContext.EventTickets
                .FirstOrDefaultAsync(t =>
                    t.EventId == seed.EventId &&
                    t.TicketType == seed.TicketType.Trim(),
                    cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Event ticket already exists: EventId {EventId}, Type {Type}",
                    existing.EventId, existing.TicketType);
                continue;
            }

            var ticket = new EventTicket(
                seed.EventId,
                seed.TicketType.Trim(),
                seed.Price,
                seed.TotalQuantity,
                seed.SaleStartDate,
                seed.SaleEndDate,
                string.IsNullOrWhiteSpace(seed.Description) ? null : seed.Description.Trim(),
                seed.PriceZoneId);

            if (!seed.IsActive)
            {
                ticket.Deactivate();
            }

            await _dbContext.EventTickets.AddAsync(ticket, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Event ticket created: TicketId {TicketId}, EventId {EventId}, Type {Type}",
                ticket.TicketId, ticket.EventId, ticket.TicketType);
        }
    }
}