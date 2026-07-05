using Microsoft.EntityFrameworkCore;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Domain.Entities;
using TicketService.Domain.Enums;
using TicketService.Infrastructure.Persistence;

namespace TicketService.Infrastructure.Repositories;

public class TicketRepository : ITicketRepository
{
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 100;

    private readonly TicketDbContext _context;

    public TicketRepository(TicketDbContext context)
    {
        _context = context;
    }

    private static (int Page, int PageSize) NormalizePaging(int page, int pageSize)
    {
        var normalizedPage = page <= 0 ? 1 : page;
        var normalizedPageSize = pageSize <= 0 ? DefaultPageSize : Math.Min(pageSize, MaxPageSize);
        return (normalizedPage, normalizedPageSize);
    }

    public async Task<PagedResult<EventAttendeePreviewDto>> GetPublicEventAttendeesAsync(
    int eventId,
    int page,
    int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        var query = _context.Reservations
            .AsNoTracking()
            .Where(r => r.EventId == eventId && r.Status == ReservationStatus.Confirmed)
            .GroupBy(r => r.UserId)
            .Select(g => new EventAttendeePreviewDto
            {
                UserId = g.Key,
                Quantity = g.Sum(x => x.Quantity)
            })
            .OrderByDescending(x => x.Quantity)
            .ThenBy(x => x.UserId);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<EventAttendeePreviewDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<List<Reservation>> GetReservationsForEventAsync(int eventId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Where(r => r.EventId == eventId)
            .OrderByDescending(r => r.ReservedAt)
            .ToListAsync();
    }

    public async Task<PagedResult<Ticket>> GetTicketsByReservationAsync(int reservationId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

        var query = _context.IssuedTickets
            .AsNoTracking()
            .Where(t => t.ReservationId == reservationId);

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(t => t.TicketId)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<Ticket>
        {
            Items = items,
            TotalCount = total,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

    public async Task<PagedResult<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

        var query = _context.PaymentDetails
            .AsNoTracking()
            .Where(p => p.ReservationId == reservationId);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(p => p.PaidAt)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<PaymentDetail>
        {
            Items = items,
            TotalCount = total,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

    public async Task<PagedResult<EventTicket>> GetEventTicketsByEventAsync(int eventId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

        var query = _context.EventTickets
            .AsNoTracking()
            .Where(t => t.EventId == eventId && t.IsActive);

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(t => t.Price)
            .ThenBy(t => t.TicketId)
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<EventTicket>
        {
            Items = items,
            TotalCount = total,
            Page = normalizedPage,
            PageSize = normalizedPageSize
        };
    }

    public async Task<Reservation?> GetReservationByIdAsync(int reservationId) =>
        await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

    public async Task<Reservation?> GetReservationByPendingProviderOrderIdAsync(string providerOrderId) =>
        await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .FirstOrDefaultAsync(r => r.PendingProviderOrderId == providerOrderId);

    public async Task<PagedResult<Reservation>> GetEventReservationsAsync(
        int eventId,
        ReservationFilterDto filter)
    {
        filter ??= new ReservationFilterDto();
        var (page, pageSize) = NormalizePaging(filter.Page, filter.PageSize);

        var query = _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .Where(r => r.EventId == eventId);

        if (filter.Status.HasValue)
            query = query.Where(r => r.Status == filter.Status.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReservedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Reservation>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<EventTicket> CreateEventTicketAsync(EventTicket eventTicket)
    {
        _context.EventTickets.Add(eventTicket);
        await _context.SaveChangesAsync();
        return eventTicket;
    }

    public async Task<int> GetEventCapacityAsync(int eventId)
    {
        return await _context.EventTickets
            .AsNoTracking()
            .Where(t => t.EventId == eventId && t.IsActive)
            .SumAsync(t => (int?)t.TotalQuantity) ?? 0;
    }

    public async Task<PagedResult<Reservation>> GetUserReservationsAsync(int userId, ReservationFilterDto filter)
    {
        filter ??= new ReservationFilterDto();
        var (page, pageSize) = NormalizePaging(filter.Page, filter.PageSize);

        var query = _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Include(r => r.Tickets)
            .Where(r => r.UserId == userId);

        if (filter.Status.HasValue)
            query = query.Where(r => r.Status == filter.Status.Value);

        if (filter.EventId.HasValue)
            query = query.Where(r => r.EventId == filter.EventId.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReservedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Reservation>
        {
            Items = items,
            TotalCount = total,
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
            .AsNoTracking()
            .Where(r => r.Status == ReservationStatus.Pending && r.ExpiresAt < DateTime.UtcNow)
            .OrderBy(r => r.ExpiresAt)
            .ToListAsync();

    public async Task<Ticket?> GetTicketByIdAsync(int ticketId) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Include(t => t.Reservation)
            .FirstOrDefaultAsync(t => t.TicketId == ticketId);

    public async Task<Ticket?> GetTicketByQrCodeAsync(string qrCode) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Include(t => t.Reservation)
            .FirstOrDefaultAsync(t => t.QrCode == qrCode);

    public async Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Where(t => t.ReservationId == reservationId)
            .OrderBy(t => t.TicketId)
            .ToListAsync();

    public async Task<PagedResult<Ticket>> GetUserTicketsAsync(int userId, TicketFilterDto filter)
    {
        filter ??= new TicketFilterDto();
        var (page, pageSize) = NormalizePaging(filter.Page, filter.PageSize);

        var query = _context.IssuedTickets
            .AsNoTracking()
            .Include(t => t.Reservation)
            .Where(t => t.UserId == userId);

        if (filter.Status.HasValue)
            query = query.Where(t => t.Status == filter.Status.Value);

        if (filter.EventId.HasValue)
            query = query.Where(t => t.EventId == filter.EventId.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(t => t.IssuedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Ticket>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<PagedResult<Ticket>> GetEventTicketsAsync(int eventId, TicketFilterDto filter)
    {
        filter ??= new TicketFilterDto();
        var (page, pageSize) = NormalizePaging(filter.Page, filter.PageSize);

        var query = _context.IssuedTickets
            .AsNoTracking()
            .Where(t => t.EventId == eventId);

        if (filter.Status.HasValue)
            query = query.Where(t => t.Status == filter.Status.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(t => t.IssuedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Ticket>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<bool> HasActiveReservationAsync(int userId, int eventTicketId) =>
        await _context.Reservations
            .AsNoTracking()
            .AnyAsync(r =>
                r.UserId == userId &&
                r.EventTicketId == eventTicketId &&
                (r.Status == ReservationStatus.Pending ||
                 r.Status == ReservationStatus.Confirmed));

    public async Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId) =>
        await _context.EventTickets
            .AsNoTracking()
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
            .AsNoTracking()
            .Where(p => p.ReservationId == reservationId)
            .OrderByDescending(p => p.PaidAt)
            .ToListAsync();

    public async Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId) =>
        await _context.PaymentDetails
            .AsNoTracking()
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
        await _context.EventTickets
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.TicketId == eventTicketId);

    public async Task AddPaymentDetailAsync(PaymentDetail payment)
    {
        await _context.PaymentDetails.AddAsync(payment);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Reservation>> GetActiveReservationsByUserAsync(int userId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Where(r => r.UserId == userId &&
                        (r.Status == ReservationStatus.Pending ||
                         r.Status == ReservationStatus.Confirmed))
            .OrderByDescending(r => r.ReservedAt)
            .ToListAsync();
    }

    public async Task<List<Reservation>> GetActiveReservationsByEventAsync(int eventId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Where(r => r.EventId == eventId &&
                        (r.Status == ReservationStatus.Pending ||
                         r.Status == ReservationStatus.Confirmed))
            .OrderByDescending(r => r.ReservedAt)
            .ToListAsync();
    }

    public async Task<int> GetEventReservationCountAsync(int eventId, ReservationStatus? status = null)
    {
        var query = _context.Reservations
            .AsNoTracking()
            .Where(r => r.EventId == eventId);

        if (status.HasValue)
            query = query.Where(r => r.Status == status.Value);

        return await query.CountAsync();
    }

    public async Task<Ticket?> GetTicketForValidationAsync(string qrCode) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Include(t => t.Reservation!)
                .ThenInclude(r => r.PaymentDetails)
            .FirstOrDefaultAsync(t => t.QrCode == qrCode);

    public async Task<int> GetEventReservedQuantityAsync(int eventId, params ReservationStatus[] statuses)
    {
        var query = _context.Reservations
            .AsNoTracking()
            .Where(r => r.EventId == eventId);

        if (statuses is { Length: > 0 })
            query = query.Where(r => statuses.Contains(r.Status));

        return await query.SumAsync(r => (int?)r.Quantity) ?? 0;
    }

    public async Task UpdatePaymentDetailAsync(PaymentDetail payment)
    {
        _context.PaymentDetails.Update(payment);
        await _context.SaveChangesAsync();
    }
}