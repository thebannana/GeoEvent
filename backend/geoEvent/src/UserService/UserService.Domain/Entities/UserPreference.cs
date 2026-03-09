namespace UserService.Domain.Entities;

public class UserPreference
{
    public int PrefId { get; set; }
    public DateTime LastUpdated { get; set; }
    public int? UserId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public double Score { get; set; } = 0.0;

    // Navigation
    public User? User { get; set; }

    // Domain logic
    public void UpdateScore(double score)
    {
        Score = score;
        LastUpdated = DateTime.UtcNow;
    }

    public void IncrementScore(double amount)
    {
        Score += amount;
        LastUpdated = DateTime.UtcNow;
    }
}
