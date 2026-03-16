namespace NotificationService.Domain.Enums;

public enum NotificationType
{
    Welcome,
    EmailVerification,
    PasswordReset,
    AccountBanned,
    EventCreated,
    EventUpdated,
    EventCancelled,
    EventStartingSoon,
    ReservationConfirmed,
    ReservationExpired,
    TicketPurchased,
    TicketCancelled,
    PaymentSucceeded,
    PaymentFailed,
    NewMessage,
    General
}
