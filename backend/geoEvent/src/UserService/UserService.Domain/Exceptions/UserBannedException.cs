namespace UserService.Domain.Exceptions;

public class UserBannedException : Exception
{
    public UserBannedException(int userId)
        : base($"User with ID {userId} is banned.") { }
}
