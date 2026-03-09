namespace LocationService.Domain.Entities;

public class City
{
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public decimal Longitude { get; set; }
    public decimal Latitude { get; set; }
    public int? DivisionId { get; set; }
    public int? CountryId { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public AdministrativeDivision? Division { get; set; }
    public Country? Country { get; set; }
    public ICollection<PostalCode> PostalCodes { get; set; } = [];
}
