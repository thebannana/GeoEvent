namespace LocationService.Domain.Exceptions;

public class AdministrativeDivisionNotFoundException : Exception
{
    public AdministrativeDivisionNotFoundException(int divisionId)
        : base($"Administrative division with ID {divisionId} was not found.") { }
}