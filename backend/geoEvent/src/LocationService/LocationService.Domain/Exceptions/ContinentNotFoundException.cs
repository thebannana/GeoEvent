namespace LocationService.Domain.Exceptions;

public class ContinentNotFoundException : Exception
{
    public ContinentNotFoundException(int continentId)
        : base($"Continent with ID {continentId} was not found.") { }
}