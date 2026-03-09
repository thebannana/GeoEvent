namespace Shared.Contracts.Notifications;

public record NotificationRequestedMessage(
    int UserId,
    string Type,
    string Title,
    string Body,
    DateTime ScheduledAt
);
