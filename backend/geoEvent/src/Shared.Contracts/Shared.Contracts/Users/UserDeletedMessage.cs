namespace Shared.Contracts.Users;

public record UserDeletedMessage(
    int UserId,
    DateTime DeletedAt
);
