namespace EventService.Application.DTOs;

public class PriceZoneResponseDto
{
    public int PriceZoneId { get; set; }
    public int VenueId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}
