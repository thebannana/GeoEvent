using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class UpdateReportStatusDto
{
    [Required]
    public string Status { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? ResolutionNote { get; set; }

    [MaxLength(255)]
    public string? ModeratorAction { get; set; }
}