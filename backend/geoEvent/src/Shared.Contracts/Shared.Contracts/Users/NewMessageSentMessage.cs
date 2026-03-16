namespace Shared.Contracts.Users;

public record NewMessageSentMessage(
    int MessageId,
    int SenderId,
    int RecipientId,
    DateTime SentAt
);
