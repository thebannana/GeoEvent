using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class VerifyEmailDto
{
    [Required]
    public string Token { get; set; } = string.Empty;
}