namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedPreferenceOptions
{
    public int UserId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public double Score { get; set; } = 1.0;
}
