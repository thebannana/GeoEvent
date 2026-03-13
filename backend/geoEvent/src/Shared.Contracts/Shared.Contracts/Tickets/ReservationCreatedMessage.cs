namespace Shared.Contracts.Tickets;

public record ReservationCreatedMessage(
    int ReservationId,
    int EventId,
    int UserId,
    int EventTicketId,
    string TicketType,
    int Quantity,
    decimal TotalAmount,
    string Currency,
    DateTime ExpiresAt,
    DateTime ReservedAt
);