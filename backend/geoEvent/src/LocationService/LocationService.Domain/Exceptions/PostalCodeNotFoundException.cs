namespace LocationService.Domain.Exceptions;

public class PostalCodeNotFoundException : Exception
{
    public PostalCodeNotFoundException(string code)
        : base($"Postal code '{code}' was not found.") { }

    public PostalCodeNotFoundException(int postalCodeId)
        : base($"Postal code with ID {postalCodeId} was not found.") { }
}