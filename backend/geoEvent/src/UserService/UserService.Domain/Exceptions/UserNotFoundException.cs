namespace UserService.Domain.Exceptions;

public class UserNotFoundException : Exception
{
    public UserNotFoundException(int userId)
        : base($"User with ID {userId} was not found.") { }

    public UserNotFoundException(string identifier)
        : base($"User '{identifier}' was not found.") { }
}
