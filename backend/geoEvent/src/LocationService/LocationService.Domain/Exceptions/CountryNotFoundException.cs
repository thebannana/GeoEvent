namespace LocationService.Domain.Exceptions;

public class CountryNotFoundException : Exception
{
    public CountryNotFoundException(int countryId)
        : base($"Country with ID {countryId} was not found.") { }
}
