namespace Shared.Contracts.Tickets;

public record TicketPurchasedMessage(
    int TicketId,
    int ReservationId,
    int EventId,
    int UserId,
    string TicketType,
    decimal Amount,
    string Currency,
    DateTime PurchasedAt
);
