namespace LocationService.Application.DTOs;

public class CityFilterDto
{
    public string? SearchTerm { get; set; }
    public int? CountryId { get; set; }
    public int? DivisionId { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
