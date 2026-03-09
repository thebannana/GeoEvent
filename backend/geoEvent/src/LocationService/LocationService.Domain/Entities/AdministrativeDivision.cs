namespace LocationService.Domain.Entities;

public class AdministrativeDivision
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
    public bool IsActive { get; set; } = true;

    // Navigation
    public Country? Country { get; set; }
    public AdministrativeDivision? ParentDivision { get; set; }
    public ICollection<AdministrativeDivision> ChildDivisions { get; set; } = [];
    public ICollection<City> Cities { get; set; } = [];
}
