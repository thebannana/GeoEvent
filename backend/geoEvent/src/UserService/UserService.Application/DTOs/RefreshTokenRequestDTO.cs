using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class RefreshTokenRequestDto
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}