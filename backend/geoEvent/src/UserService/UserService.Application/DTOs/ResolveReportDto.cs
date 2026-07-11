using System.ComponentModel.DataAnnotations;
using UserService.Domain.Enums;

namespace UserService.Application.DTOs;

public class ResolveReportDto
{
    [Required]
    public ReportResolutionAction Action { get; set; }

    [MaxLength(1000)]
    public string? ResolutionNote { get; set; }

    [MaxLength(255)]
    public string? ModeratorAction { get; set; }
}