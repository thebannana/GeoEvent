namespace LocationService.Domain.Exceptions;

public class CityNotFoundException : Exception
{
    public CityNotFoundException(int cityId)
        : base($"City with ID {cityId} was not found.") { }
}
