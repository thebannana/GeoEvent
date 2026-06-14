namespace EventService.Application.DTOs;

public class UserPreferenceDto
{
    public int PrefId { get; set; }
    public int? UserId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public double Score { get; set; }
    public DateTime LastUpdated { get; set; }
}