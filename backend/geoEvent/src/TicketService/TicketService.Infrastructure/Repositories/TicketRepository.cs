using Microsoft.EntityFrameworkCore;
using TicketService.Application.Common;
using TicketService.Application.DTOs;
using TicketService.Application.Interfaces.Persistence;
using TicketService.Application.Interfaces.Repositories;
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

    public async Task<PagedResult<Reservation>> GetRefundRequestsAsync(AdminRefundRequestsQueryDto query)
    {
        query ??= new AdminRefundRequestsQueryDto();
        var (page, pageSize) = NormalizePaging(query.Page, query.PageSize);

        var reservations = _context.Reservations
            .AsNoTracking()
            .Include(r => r.PaymentDetails)
            .Include(r => r.Tickets)
            .Where(r => r.RefundRequestStatus != RefundRequestStatus.None);

        if (query.EventId.HasValue)
            reservations = reservations.Where(r => r.EventId == query.EventId.Value);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            reservations = reservations.Where(r =>
                (r.RefundReason != null && r.RefundReason.ToLower().Contains(search)) ||
                r.ReservationId.ToString().Contains(search) ||
                r.UserId.ToString().Contains(search));
        }

        if (query.Status.HasValue)
        {
            reservations = query.Status.Value switch
            {
                RefundQueueStatus.Open =>
                    reservations.Where(r => r.RefundRequestStatus == RefundRequestStatus.Pending),

                RefundQueueStatus.InReview =>
                    reservations.Where(r => r.RefundRequestStatus == RefundRequestStatus.Processing),

                RefundQueueStatus.Resolved =>
                    reservations.Where(r => r.RefundRequestStatus == RefundRequestStatus.Approved),

                RefundQueueStatus.Rejected =>
                    reservations.Where(r => r.RefundRequestStatus == RefundRequestStatus.Rejected),

                _ => reservations
            };
        }

        reservations = (query.SortBy ?? string.Empty).Trim().ToLowerInvariant() switch
        {
            "status" => query.Descending
                ? reservations.OrderByDescending(r => r.RefundRequestStatus)
                : reservations.OrderBy(r => r.RefundRequestStatus),

            "amount" => query.Descending
                ? reservations.OrderByDescending(r => r.TotalAmount)
                : reservations.OrderBy(r => r.TotalAmount),

            _ => query.Descending
                ? reservations.OrderByDescending(r => r.RefundRequestedAt ?? r.CreatedAt)
                : reservations.OrderBy(r => r.RefundRequestedAt ?? r.CreatedAt)
        };

        var total = await reservations.CountAsync();

        var items = await reservations
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
    public async Task<AdminDashboardTicketStatsDto> GetAdminDashboardTicketStatsAsync(string currency = "BAM")
    {
        currency = string.IsNullOrWhiteSpace(currency)
            ? "BAM"
            : currency.Trim().ToUpperInvariant();

        var totalReservations = await _context.Reservations
            .AsNoTracking()
            .CountAsync();

        var pendingReservations = await _context.Reservations
            .AsNoTracking()
            .CountAsync(r => r.Status == ReservationStatus.Pending);

        var confirmedReservations = await _context.Reservations
            .AsNoTracking()
            .CountAsync(r => r.Status == ReservationStatus.Confirmed);

        var cancelledReservations = await _context.Reservations
            .AsNoTracking()
            .CountAsync(r => r.Status == ReservationStatus.Cancelled);

        var expiredReservations = await _context.Reservations
            .AsNoTracking()
            .CountAsync(r => r.Status == ReservationStatus.Expired);

        var totalTickets = await _context.IssuedTickets
            .AsNoTracking()
            .CountAsync();

        var activeTickets = await _context.IssuedTickets
            .AsNoTracking()
            .CountAsync(t => t.Status == TicketStatus.Active);

        var usedTickets = await _context.IssuedTickets
            .AsNoTracking()
            .CountAsync(t => t.Status == TicketStatus.Used);

        var cancelledTickets = await _context.IssuedTickets
            .AsNoTracking()
            .CountAsync(t => t.Status == TicketStatus.Cancelled);

        var paymentQuery = _context.PaymentDetails
            .AsNoTracking()
            .Where(p => p.Currency == currency);

        var totalPayments = await paymentQuery.CountAsync();

        var completedPayments = await paymentQuery
            .CountAsync(p => p.Status == PaymentStatus.Completed);

        var pendingPayments = await paymentQuery
            .CountAsync(p => p.Status == PaymentStatus.Pending);

        var refundedPayments = await paymentQuery
            .CountAsync(p => p.Status == PaymentStatus.Refunded);

        var grossRevenue = await paymentQuery
            .Where(p => p.Status == PaymentStatus.Completed)
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        var refundedAmount = await paymentQuery
            .Where(p => p.Status == PaymentStatus.Refunded)
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        var payPalRevenue = await paymentQuery
            .Where(p => p.Status == PaymentStatus.Completed && p.Method == PaymentMethod.PayPal)
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        var cashRevenue = await paymentQuery
            .Where(p => p.Status == PaymentStatus.Completed && p.Method == PaymentMethod.Cash)
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        var pendingCashRevenue = await paymentQuery
            .Where(p => p.Status == PaymentStatus.Pending && p.Method == PaymentMethod.Cash)
            .SumAsync(p => (decimal?)p.Amount) ?? 0m;

        return new AdminDashboardTicketStatsDto
        {
            TotalReservations = totalReservations,
            PendingReservations = pendingReservations,
            ConfirmedReservations = confirmedReservations,
            CancelledReservations = cancelledReservations,
            ExpiredReservations = expiredReservations,

            TotalTickets = totalTickets,
            ActiveTickets = activeTickets,
            UsedTickets = usedTickets,
            CancelledTickets = cancelledTickets,

            GrossRevenue = grossRevenue,
            RefundedAmount = refundedAmount,
            NetRevenue = grossRevenue - refundedAmount,

            PayPalRevenue = payPalRevenue,
            CashRevenue = cashRevenue,
            PendingCashRevenue = pendingCashRevenue,

            TotalPayments = totalPayments,
            CompletedPayments = completedPayments,
            PendingPayments = pendingPayments,
            RefundedPayments = refundedPayments,

            Currency = currency
        };
    }

    public async Task ExecuteInStrategyAsync(Func<Task> operation)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(operation);
    }

    public async Task<IAppTransaction> BeginTransactionAsync()
    {
        var tx = await _context.Database.BeginTransactionAsync();
        return new EfAppTransaction(tx);
    }

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();

    public async Task<EventTicket> CreateEventTicketAsync(EventTicket eventTicket)
    {
        _context.EventTickets.Add(eventTicket);
        return eventTicket;
    }

    public async Task<Reservation> CreateReservationAsync(Reservation reservation)
    {
        await _context.Reservations.AddAsync(reservation);
        return reservation;
    }

    public async Task AddTicketsAsync(IEnumerable<Ticket> tickets)
    {
        await _context.IssuedTickets.AddRangeAsync(tickets);
    }

    public async Task AddPaymentDetailAsync(PaymentDetail payment)
    {
        await _context.PaymentDetails.AddAsync(payment);
    }

    public Task UpdateReservationAsync(Reservation reservation)
    {
        _context.Entry(reservation).State = EntityState.Modified;
        return Task.CompletedTask;
    }

    public Task UpdateEventTicketAsync(EventTicket eventTicket)
    {
        _context.Entry(eventTicket).State = EntityState.Modified;
        return Task.CompletedTask;
    }

    public Task UpdateTicketAsync(Ticket ticket)
    {
        _context.Entry(ticket).State = EntityState.Modified;
        return Task.CompletedTask;
    }

    public Task UpdatePaymentDetailAsync(PaymentDetail payment)
    {
        _context.Entry(payment).State = EntityState.Modified;
        return Task.CompletedTask;
    }

    public async Task<Reservation?> GetReservationByIdAsync(int reservationId) =>
        await _context.Reservations
            .AsNoTracking()
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

    public async Task<Reservation?> GetReservationByIdForUpdateAsync(int reservationId) =>
        await _context.Reservations
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .FirstOrDefaultAsync(r => r.ReservationId == reservationId);

    public async Task<Reservation?> GetReservationByPendingProviderOrderIdAsync(string providerOrderId) =>
        await _context.Reservations
            .AsNoTracking()
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .FirstOrDefaultAsync(r => r.PendingProviderOrderId == providerOrderId);

    public async Task<Reservation?> GetReservationByPendingProviderOrderIdForUpdateAsync(string providerOrderId) =>
        await _context.Reservations
            .Include(r => r.Tickets)
            .Include(r => r.PaymentDetails)
            .FirstOrDefaultAsync(r => r.PendingProviderOrderId == providerOrderId);

    public async Task<EventTicket?> GetEventTicketByIdAsync(int eventTicketId) =>
        await _context.EventTickets
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.TicketId == eventTicketId);

    public async Task<EventTicket?> GetEventTicketByIdForUpdateAsync(int eventTicketId) =>
        await _context.EventTickets
            .FirstOrDefaultAsync(t => t.TicketId == eventTicketId);

    public async Task<List<Ticket>> GetTicketsByReservationForUpdateAsync(int reservationId) =>
        await _context.IssuedTickets
            .Where(t => t.ReservationId == reservationId)
            .OrderBy(t => t.TicketId)
            .ToListAsync();

    public async Task<List<PaymentDetail>> GetPaymentsByReservationForUpdateAsync(int reservationId) =>
        await _context.PaymentDetails
            .Where(p => p.ReservationId == reservationId)
            .OrderByDescending(p => p.PaidAt)
            .ToListAsync();

    public async Task<List<Ticket>> GetTicketsByReservationAsync(int reservationId) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Where(t => t.ReservationId == reservationId)
            .OrderBy(t => t.TicketId)
            .ToListAsync();

    public async Task<List<PaymentDetail>> GetPaymentsByReservationAsync(int reservationId) =>
        await _context.PaymentDetails
            .AsNoTracking()
            .Where(p => p.ReservationId == reservationId)
            .OrderByDescending(p => p.PaidAt)
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

    public async Task<Ticket?> GetTicketForValidationAsync(string qrCode) =>
        await _context.IssuedTickets
            .AsNoTracking()
            .Include(t => t.Reservation!)
                .ThenInclude(r => r.PaymentDetails)
            .FirstOrDefaultAsync(t => t.QrCode == qrCode);

    public async Task<PaymentDetail?> GetPaymentByTransactionIdAsync(string transactionId) =>
        await _context.PaymentDetails
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.TransactionId == transactionId);

    public async Task<PagedResult<EventAttendeePreviewDto>> GetPublicEventAttendeesAsync(int eventId, int page, int pageSize)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

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
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<EventAttendeePreviewDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = normalizedPage,
            PageSize = normalizedPageSize
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

    public async Task<PagedResult<ManageableEventAttendeePreviewDto>> GetManageableEventAttendeesAsync(
    int eventId,
    int page,
    int pageSize,
    string? searchTerm)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);

        var query = _context.Reservations
            .AsNoTracking()
            .Where(r =>
                r.EventId == eventId &&
                (r.Status == ReservationStatus.Pending ||
                 r.Status == ReservationStatus.Confirmed));

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.Trim();
            query = query.Where(r => r.UserId.ToString().Contains(term));
        }

        var groupedQuery = query
            .GroupBy(r => r.UserId)
            .Select(g => new ManageableEventAttendeePreviewDto
            {
                ReservationId = g
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => x.ReservationId)
                    .FirstOrDefault(),
                UserId = g.Key,
                Quantity = g.Sum(x => x.Quantity),
                Username = string.Empty,
                AvatarUrl = null
            })
            .OrderByDescending(x => x.Quantity)
            .ThenBy(x => x.UserId);

        var totalCount = await groupedQuery.CountAsync();

        var items = await groupedQuery
            .Skip((normalizedPage - 1) * normalizedPageSize)
            .Take(normalizedPageSize)
            .ToListAsync();

        return new PagedResult<ManageableEventAttendeePreviewDto>
        {
            Items = items,
            TotalCount = totalCount,
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

    public async Task<PagedResult<Reservation>> GetEventReservationsAsync(int eventId, ReservationFilterDto filter)
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

    public async Task<List<Reservation>> GetExpiredReservationsAsync() =>
        await _context.Reservations
            .AsNoTracking()
            .Where(r => r.Status == ReservationStatus.Pending && r.ExpiresAt < DateTime.UtcNow)
            .OrderBy(r => r.ExpiresAt)
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
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed));

    public async Task<List<EventTicket>> GetEventTicketsByEventAsync(int eventId) =>
        await _context.EventTickets
            .AsNoTracking()
            .Where(t => t.EventId == eventId && t.IsActive)
            .OrderBy(t => t.Price)
            .ToListAsync();

    public async Task<List<Reservation>> GetActiveReservationsByUserAsync(int userId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Where(r => r.UserId == userId &&
                        (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed))
            .OrderByDescending(r => r.ReservedAt)
            .ToListAsync();
    }

    public async Task<Ticket?> GetTicketForValidationForUpdateAsync(string qrCode)
    {
        return await _context.IssuedTickets
            .Include(t => t.Reservation!)
                .ThenInclude(r => r.PaymentDetails)
            .FirstOrDefaultAsync(t => t.QrCode == qrCode);
    }

    public async Task<List<Reservation>> GetActiveReservationsByEventAsync(int eventId)
    {
        return await _context.Reservations
            .AsNoTracking()
            .Include(r => r.EventTicket)
            .Where(r => r.EventId == eventId &&
                        (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Confirmed))
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

    public async Task<int> GetEventReservedQuantityAsync(int eventId, params ReservationStatus[] statuses)
    {
        var query = _context.Reservations
            .AsNoTracking()
            .Where(r => r.EventId == eventId);

        if (statuses is { Length: > 0 })
            query = query.Where(r => statuses.Contains(r.Status));

        return await query.SumAsync(r => (int?)r.Quantity) ?? 0;
    }
}