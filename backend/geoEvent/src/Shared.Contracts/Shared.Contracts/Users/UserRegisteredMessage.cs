namespace Shared.Contracts.Users;

public record UserRegisteredMessage(
    int UserId,
    string Email,
    string Username,
    string FirstName,
    DateTime RegisteredAt
);