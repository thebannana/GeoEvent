namespace LocationService.Application.DTOs;

public class CityResponseDto
{
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public decimal Longitude { get; set; }
    public decimal Latitude { get; set; }
    public int? DivisionId { get; set; }
    public string? DivisionName { get; set; }
    public int? CountryId { get; set; }
    public string? CountryName { get; set; }
    public bool IsActive { get; set; }
}
