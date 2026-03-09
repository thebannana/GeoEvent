using Microsoft.EntityFrameworkCore;
using TicketService.Application.Common;
using TicketService.Application.Interfaces.Repositories;
using TicketService.Domain.Entities;
using TicketService.Infrastructure.Persistence;

namespace TicketService.Infrastructure.Repositories;

public class TicketRepository : ITicketRepository
{
    private readonly TicketDbContext _context;

    public TicketRepository(TicketDbContext context)
    {
        _context = context;
    }

    public async Task<Reservation?> GetReservationByIdAsync(int reservationId) =>
        await _context.Reservations
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

    public async Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, int page, int pageSize)
    {
        var query = _context.Reservations
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.ReservedAt);

        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Reservation>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<Reservation> CreateReservationAsync(Reservation reservation)
    {
        await _context.Reservations.AddAsync(reservation);
        await _context.SaveChangesAsync();
        return reservation;
    }

    public async Task UpdateReservationAsync(Reservation reservation)
    {
        _context.Reservations.Update(reservation);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Reservation>> GetExpiredReservationsAsync() =>
        await _context.Reservations
            .Where(r => r.Status == Domain.Enums.ReservationStatus.Pending && r.ExpiresAt < DateTime.UtcNow)
            .ToListAsync();

    public async Task<Ticket?> GetTicketByIdAsync(int ticketId) =>
        await _context.IssuedTickets
            .Include(t => t.Reservation)
            .FirstOrDefaultAsync(t => t.TicketId == ticketId);

    public async Task<Ticket?> GetTicketByQrCodeAsync(string qrCode) =>
        await _context.IssuedTickets
            .Include(t => t.Reservation)
            .FirstOrDefaultAsync(t => t.QrCode == qrCode);

    public async Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId) =>
        await _context.IssuedTickets
            .Where(t => t.ReservationId == reservationId)
            .ToListAsync();

    public async Task<List<Ticket>> GetUserTicketsAsync(int userId) =>
        await _context.IssuedTickets
            .Include(t => t.Reservation)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.IssuedAt)
            .ToListAsync();

    public async Task<List<Ticket>> GetEventTicketsAsync(int eventId) =>
        await _context.IssuedTickets
            .Where(t => t.EventId == eventId)
            .ToListAsync();

    public async Task AddTicketsAsync(IEnumerable<Ticket> tickets)
    {
        await _context.IssuedTickets.AddRangeAsync(tickets);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateTicketAsync(Ticket ticket)
    {
        _context.IssuedTickets.Update(ticket);
        await _context.SaveChangesAsync();
    }

    public async Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId) =>
        await _context.EventTickets.FindAsync(eventTicketId);

    public async Task<EventTicket?> GetEventTicketByEventAndTypeAsync(int eventId, string ticketType) =>
        await _context.EventTickets
            .FirstOrDefaultAsync(t => t.EventId == eventId && t.TicketType == ticketType && t.IsActive);

    public async Task AddPaymentDetailAsync(PaymentDetail payment)
    {
        await _context.PaymentDetails.AddAsync(payment);
        await _context.SaveChangesAsync();
    }
}
