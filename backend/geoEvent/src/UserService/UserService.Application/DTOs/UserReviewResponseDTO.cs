namespace UserService.Application.DTOs;

public class UserReviewResponseDto
{
    public int RatingId { get; set; }
    public int ReviewerId { get; set; }
    public string ReviewerUsername { get; set; } = string.Empty;
    public string ReviewerDisplayName { get; set; } = string.Empty;
    public string? ReviewerImageUrl { get; set; }

    public int RatedUserId { get; set; }
    public int Value { get; set; }
    public string? Comment { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}