namespace Shared.Contracts.Notifications;
using Shared.Contracts.Enums;

public record NotificationRequestedMessage(
    int UserId,
    NotificationType Type,
    string Title,
    string Body,
    DateTime ScheduledAt
);

