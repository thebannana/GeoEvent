namespace NotificationService.Domain.Enums;

public enum NotificationType
{
    ReservationCreated,
    ReservationConfirmed,
    ReservationCancelled,
    ReservationExpired,
    TicketIssued,
    TicketCancelled,
    TicketValidated,
    EventUpdated,
    EventCancelled,
    General
}
