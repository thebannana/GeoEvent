namespace UserService.Application.DTOs;

public class AdminUpdateUserDto
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ImageUrl { get; set; }
    public string Role { get; set; } = string.Empty;
}