namespace UserService.Domain.Entities;

public class UserRating
{
    public int RatingId { get; set; }
    public int RaterId { get; set; }
    public int RatedUserId { get; set; }
    public int Value { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User? Rater { get; set; }
    public User? RatedUser { get; set; }

    public void UpdateReview(int value, string? comment)
    {
        Value = value;
        Comment = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();
        UpdatedAt = DateTime.UtcNow;
    }
}