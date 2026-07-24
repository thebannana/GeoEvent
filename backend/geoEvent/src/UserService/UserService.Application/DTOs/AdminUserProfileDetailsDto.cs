namespace UserService.Application.DTOs;

public class AdminUserProfileDetailsDto
{
    public int UserId { get; set; }

    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName =>
        string.Join(" ", new[] { FirstName, LastName }.Where(x => !string.IsNullOrWhiteSpace(x)));

    public string? PhoneNumber { get; set; }
    public string? ImageUrl { get; set; }
    public string? Bio { get; set; }

    public string Role { get; set; } = string.Empty;
    public bool IsBanned { get; set; }

    public DateTime CreatedAt { get; set; }

    public int EventsCount { get; set; }

    public double AverageRating { get; set; }
    public int RatingsCount { get; set; }

}