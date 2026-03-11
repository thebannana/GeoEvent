namespace LocationService.Application.DTOs;

public class DivisionFilterDto
{
    public int? CountryId { get; set; }
    public int? ParentDivisionId { get; set; }
    public int? Level { get; set; }
    public bool? IsActive { get; set; }
    public string? DivisionType { get; set; }
}
