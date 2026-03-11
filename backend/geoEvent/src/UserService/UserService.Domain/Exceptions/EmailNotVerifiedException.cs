namespace UserService.Domain.Exceptions;

public class EmailNotVerifiedException : Exception
{
    public EmailNotVerifiedException()
        : base("Email address has not been verified.") { }
}