namespace Shared.Contracts.Messages;

public record NewMessageSentMessage(
    int MessageId,
    int SenderId,
    int RecipientId,
    DateTime SentAt
);
