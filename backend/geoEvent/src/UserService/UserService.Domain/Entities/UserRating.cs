namespace UserService.Domain.Entities;

public class UserRating
{
    public int RatingId { get; set; }
    public int RaterId { get; private set; }
    public int RatedUserId { get; private set; }
    public int Value { get; private set; }
    public string? Comment { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; private set; }

    public User? Rater { get; set; }
    public User? RatedUser { get; set; }

    private UserRating() { }

    public UserRating(int raterId, int ratedUserId, int value, string? comment)
    {
        if (raterId <= 0)
            throw new ArgumentException("Rater ID must be greater than zero.", nameof(raterId));

        if (ratedUserId <= 0)
            throw new ArgumentException("Rated user ID must be greater than zero.", nameof(ratedUserId));

        ValidateValue(value);

        RaterId = raterId;
        RatedUserId = ratedUserId;
        Value = value;
        Comment = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();
        CreatedAt = DateTime.UtcNow;
    }

    public void UpdateReview(int value, string? comment)
    {
        ValidateValue(value);

        Value = value;
        Comment = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim();
        UpdatedAt = DateTime.UtcNow;
    }

    public static void ValidateValue(int value)
    {
        if (value < 1 || value > 5)
            throw new ArgumentException("Rating value must be between 1 and 5.", nameof(value));
    }
}