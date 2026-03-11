using Microsoft.EntityFrameworkCore;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Repositories;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;
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

    public async Task<PagedResult<Reservation>> GetUserReservationsAsync(
    int userId, ReservationFilterDto filter)
    {
        var query = _context.Reservations
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .Where(r => r.UserId == userId);

        if (filter.Status.HasValue)
            query = query.Where(r => r.Status == filter.Status.Value);

        if (filter.EventId.HasValue)
            query = query.Where(r => r.EventId == filter.EventId.Value);

        query = query.OrderByDescending(r => r.ReservedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Reservation>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
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

    public async Task<PagedResult<Ticket>> GetUserTicketsAsync(
    int userId, TicketFilterDto filter)
    {
        var query = _context.IssuedTickets
            .Include(t => t.Reservation)
            .Where(t => t.UserId == userId);

        if (filter.Status.HasValue)
            query = query.Where(t => t.Status == filter.Status.Value);

        if (filter.EventId.HasValue)
            query = query.Where(t => t.EventId == filter.EventId.Value);

        query = query.OrderByDescending(t => t.IssuedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Ticket>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }


    public async Task<PagedResult<Ticket>> GetEventTicketsAsync(
    int eventId, TicketFilterDto filter)
    {
        var query = _context.IssuedTickets
            .Where(t => t.EventId == eventId);

        if (filter.Status.HasValue)
            query = query.Where(t => t.Status == filter.Status.Value);

        query = query.OrderByDescending(t => t.IssuedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Ticket>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<bool> HasActiveReservationAsync(int userId, int eventTicketId) =>
    await _context.Reservations
        .AnyAsync(r =>
            r.UserId == userId &&
            r.EventTicketId == eventTicketId &&
            (r.Status == ReservationStatus.Pending ||
             r.Status == ReservationStatus.Confirmed));

    public async Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId) =>
    await _context.EventTickets
        .Where(t => t.EventId == eventId && t.IsActive)
        .OrderBy(t => t.Price)
        .ToListAsync();

    public async Task UpdateEventTicketAsync(EventTicket eventTicket)
    {
        _context.EventTickets.Update(eventTicket);
        await _context.SaveChangesAsync();
    }

    public async Task<List<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId) =>
    await _context.PaymentDetails
        .Where(p => p.ReservationId == reservationId)
        .OrderByDescending(p => p.PaidAt)
        .ToListAsync();

    public async Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId) =>
    await _context.PaymentDetails
        .FirstOrDefaultAsync(p => p.TransactionId == transactionId);


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

    public async Task AddPaymentDetailAsync(PaymentDetail payment)
    {
        await _context.PaymentDetails.AddAsync(payment);
        await _context.SaveChangesAsync();
    }
}
