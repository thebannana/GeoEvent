namespace LocationService.Domain.Entities;

public class City
{
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string NormalizedName { get; set; } = string.Empty;
    public decimal Longitude { get; set; }
    public decimal Latitude { get; set; }
    public int? DivisionId { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public AdministrativeDivision? Division { get; set; }
    public ICollection<PostalCode> PostalCodes { get; set; } = [];

    // Domain logic
    public double DistanceTo(decimal lat, decimal lon)
    {
        const double R = 6371;
        var dLat = ToRad((double)(lat - Latitude));
        var dLon = ToRad((double)(lon - Longitude));
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRad((double)Latitude)) *
                Math.Cos(ToRad((double)lat)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    private static double ToRad(double deg) => deg * Math.PI / 180;
}
