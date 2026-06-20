namespace EventService.Domain.Exceptions;

public class InvalidReferenceDataException : Exception
{
    public InvalidReferenceDataException(string message) : base(message) { }
}