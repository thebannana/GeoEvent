namespace NotificationService.Domain.Enums;

public enum NotificationType
{
    // Reservations
    ReservationCreated,
    ReservationConfirmed,
    ReservationCancelled,
    ReservationExpired,

    // Tickets
    TicketIssued,
    TicketCancelled,
    TicketValidated,

    // Events
    EventUpdated,
    EventCancelled,
    EventReminder,

    // Social
    NewMessage,
    ReportResolved,

    // Account
    EmailVerification,
    PasswordReset,
    AccountBanned,
    AccountUnbanned,

    General
}
