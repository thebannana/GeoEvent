namespace UserService.Application.DTOs;

public class PublicUserProfileDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
}