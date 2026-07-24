namespace UserService.Application.DTOs;
public sealed class ExternalReviewLookupDto
{
    public int ReviewId { get; set; }
    public int ReviewerId { get; set; }
    public int RatedUserId { get; set; }
    public int Value { get; set; }
    public string? Username { get; set; }
    public string? UserDisplayName { get; set; }
    public string Preview { get; set; } = string.Empty;
}
