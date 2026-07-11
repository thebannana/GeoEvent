using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class UpdateProfileDto
{
    [StringLength(50, MinimumLength = 3)]
    public string? Username { get; set; }

    [EmailAddress]
    public string? Email { get; set; }

    [StringLength(100, MinimumLength = 2)]
    public string? FirstName { get; set; }

    [StringLength(100, MinimumLength = 2)]
    public string? LastName { get; set; }

    [Phone]
    [RegularExpression(@"^\+?[1-9]\d{1,14}$", ErrorMessage = "Invalid phone number format.")]
    public string? PhoneNumber { get; set; }

    [Url]
    public string? ImageUrl { get; set; }
}