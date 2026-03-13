namespace Shared.Contracts.Tickets;

public record TicketCancelledMessage(
    int TicketId,
    int EventId,
    int UserId,
    string Reason,
    DateTime CancelledAt
);
