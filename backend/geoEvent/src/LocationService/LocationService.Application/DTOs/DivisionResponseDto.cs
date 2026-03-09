namespace LocationService.Application.DTOs;

public class DivisionResponseDto
{
    public int DivisionId { get; set; }
    public int? CountryId { get; set; }
    public int? ParentDivisionId { get; set; }
    public string DivisionName { get; set; } = string.Empty;
    public string DivisionCode { get; set; } = string.Empty;
    public string DivisionType { get; set; } = string.Empty;
    public int Level { get; set; }
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public bool IsActive { get; set; }
}
