namespace TicketService.Domain.Enums;

public enum RefundRequestStatus
{
    None = 0,
    Pending = 1,
    Approved = 2,
    Rejected = 3,
    Processing = 4,
    Refunded = 5,
    Failed = 6
}