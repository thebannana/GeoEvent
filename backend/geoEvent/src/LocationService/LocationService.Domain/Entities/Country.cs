namespace LocationService.Domain.Entities;

public class Country
{
    public int CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public string CountryCodeAlpha2 { get; set; } = string.Empty;
    public string CountryCodeAlpha3 { get; set; } = string.Empty;
    public int CountryCodeNumeric { get; set; }
    public bool IsActive { get; set; } = true;
    public int? ContinentId { get; set; }

    // Navigation
    public Continent? Continent { get; set; }
    public ICollection<AdministrativeDivision> Divisions { get; set; } = [];
    public ICollection<City> Cities { get; set; } = [];
}
