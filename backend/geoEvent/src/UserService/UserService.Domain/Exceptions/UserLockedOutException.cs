namespace UserService.Domain.Exceptions;

public class UserLockedOutException : Exception
{
    public UserLockedOutException(DateTime lockedUntil)
        : base($"Account is locked until {lockedUntil:u}.") { }
}