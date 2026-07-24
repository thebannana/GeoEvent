using SeedGeneration.SeedGenerator.Configuration;

namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedSettings
{
    public List<SeedAdminOptions> SeedAdmins { get; set; } = new();
}