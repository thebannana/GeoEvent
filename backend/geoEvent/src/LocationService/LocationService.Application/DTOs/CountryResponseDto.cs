namespace LocationService.Application.DTOs;

public class CountryResponseDto
{
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public string CountryCodeAlpha2 { get; set; } = string.Empty;
    public string CountryCodeAlpha3 { get; set; } = string.Empty;
    public int CountryCodeNumeric { get; set; }
    public bool IsActive { get; set; }
    public int? ContinentId { get; set; }
    public string? ContinentName { get; set; }
}
