namespace Shared.Contracts.Users;

public record EmailVerificationRequestedMessage(
    int UserId,
    string Email,
    string Token,
    DateTime ExpiresAt
);