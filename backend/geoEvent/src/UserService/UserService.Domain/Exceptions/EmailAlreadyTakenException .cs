namespace UserService.Domain.Exceptions;

public class EmailAlreadyTakenException : Exception
{
    public EmailAlreadyTakenException(string email)
        : base($"The email '{email}' is already registered.") { }
}