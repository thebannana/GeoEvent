namespace TicketService.Application.DTOs;

public class AdminDashboardTicketStatsDto
{
    public int TotalReservations { get; set; }
    public int PendingReservations { get; set; }
    public int ConfirmedReservations { get; set; }
    public int CancelledReservations { get; set; }
    public int ExpiredReservations { get; set; }

    public int TotalTickets { get; set; }
    public int ActiveTickets { get; set; }
    public int UsedTickets { get; set; }
    public int CancelledTickets { get; set; }

    public decimal GrossRevenue { get; set; }
    public decimal NetRevenue { get; set; }
    public decimal RefundedAmount { get; set; }

    public decimal PayPalRevenue { get; set; }
    public decimal CashRevenue { get; set; }
    public decimal PendingCashRevenue { get; set; }

    public int TotalPayments { get; set; }
    public int CompletedPayments { get; set; }
    public int PendingPayments { get; set; }
    public int RefundedPayments { get; set; }

    public string Currency { get; set; } = "BAM";
}