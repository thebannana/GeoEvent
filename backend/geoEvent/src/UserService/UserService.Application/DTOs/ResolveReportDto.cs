using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class ResolveReportDto
{
    [Required]
    public string Action { get; set; } = string.Empty; // "Resolve" or "Dismiss"
}
