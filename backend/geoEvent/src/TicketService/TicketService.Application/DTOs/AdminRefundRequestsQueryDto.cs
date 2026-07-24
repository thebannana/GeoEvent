namespace TicketService.Application.DTOs;

public class AdminRefundRequestsQueryDto
{
    public int? EventId { get; set; }
    public string? Search { get; set; }
    public RefundQueueStatus? Status { get; set; }
    public string? SortBy { get; set; } = "createdAt";
    public bool Descending { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}