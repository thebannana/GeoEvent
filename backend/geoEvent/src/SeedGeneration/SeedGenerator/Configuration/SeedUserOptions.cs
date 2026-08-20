namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedUserOptions
{
    public string FirstName { get; set; } = "User";
    public string LastName { get; set; } = "GeoEvent";
    public string Username { get; set; } = "user";
    public string Email { get; set; } = "user@geoevent.local";
    public string Password { get; set; } = "User123!";
    public string PhoneNumber { get; set; } = "+38761000000";
    public DateTime BirthDate { get; set; } = new(2000, 1, 1);
    public string ConsentVersion { get; set; } = "1.0";
}