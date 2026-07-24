namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedAdminOptions
{
    public string FirstName { get; set; } = "Admin";
    public string LastName { get; set; } = "GeoEvent";
    public string Username { get; set; } = "admin";
    public string Email { get; set; } = "admin@geoevent.local";
    public string Password { get; set; } = "Admin123!";
    public string PhoneNumber { get; set; } = "+38760000000";
    public DateTime BirthDate { get; set; } = new(2000, 1, 1);
    public string ConsentVersion { get; set; } = "1.0";
}