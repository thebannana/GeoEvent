namespace UserService.Application.DTOs;

public class UserProfileDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ImageUrl { get; set; }
    public string Role { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? CityId { get; set; }
    public string? CityName { get; set; }

    public double AverageRating { get; set; }
    public int RatingsCount { get; set; }
    public int? MyRating { get; set; }
}