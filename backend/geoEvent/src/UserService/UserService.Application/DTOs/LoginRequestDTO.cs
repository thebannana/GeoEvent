using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class LoginRequestDto
{
    [Required]
    public string Identifier { get; set; } = string.Empty; // email or username

    [Required]
    public string Password { get; set; } = string.Empty;

    public string? DeviceInfo { get; set; }
}
