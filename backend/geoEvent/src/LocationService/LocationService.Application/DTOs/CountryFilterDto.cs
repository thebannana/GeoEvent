namespace LocationService.Application.DTOs;

public class CountryFilterDto
{
    public int? ContinentId { get; set; }
    public bool? IsActive { get; set; }
    public string? SearchTerm { get; set; }
}
