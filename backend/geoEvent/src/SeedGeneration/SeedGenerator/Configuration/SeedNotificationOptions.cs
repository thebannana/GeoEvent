namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedNotificationOptions
{
    public string Type { get; set; } = "General";
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int UserId { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsRead { get; set; } = false;
}