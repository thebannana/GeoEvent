using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace UserService.Application.DTOs;

public class LoginRequestDto
{
    [Required]
    [JsonPropertyName("emailOrUsername")]
    public string Identifier { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

    public string? DeviceInfo { get; set; }
}
