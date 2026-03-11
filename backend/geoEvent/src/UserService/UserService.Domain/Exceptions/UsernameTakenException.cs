namespace UserService.Domain.Exceptions;

public class UsernameTakenException : Exception
{
    public UsernameTakenException(string username)
        : base($"The username '{username}' is already taken.") { }
}