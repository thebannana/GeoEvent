namespace EventService.Domain.Exceptions;

public class VenueNotFoundException : Exception
{
    public VenueNotFoundException(int venueId)
        : base($"Venue with ID {venueId} was not found.") { }
}