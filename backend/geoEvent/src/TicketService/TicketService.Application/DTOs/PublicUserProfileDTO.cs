public class PublicUserProfileDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? Bio { get; set; }
    public string? CityName { get; set; }
    public int EventsCount { get; set; }
    public int FollowersCount { get; set; }
    public int FollowingCount { get; set; }
    public double AverageRating { get; set; }
    public int RatingsCount { get; set; }
    public int? MyRating { get; set; }
    public string? MyReviewComment { get; set; }
}