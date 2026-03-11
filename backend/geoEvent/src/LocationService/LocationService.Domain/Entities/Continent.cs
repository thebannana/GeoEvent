namespace LocationService.Domain.Entities;

public class Continent
{
    public int ContinentId { get; set; }
    public string ContinentName { get; set; } = string.Empty;
    public string ContinentCode { get; set; } = string.Empty;

    // Navigation
    public ICollection<Country> Countries { get; set; } = [];
}
