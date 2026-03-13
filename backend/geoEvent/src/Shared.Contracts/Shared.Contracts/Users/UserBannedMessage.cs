namespace Shared.Contracts.Users;

public record UserBannedMessage(
    int UserId,
    string Username,
    string Reason,
    DateTime BannedAt
);