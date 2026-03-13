namespace Shared.Contracts.Users;

public record PasswordResetRequestedMessage(
    int UserId,
    string Email,
    string Token,
    DateTime ExpiresAt
);