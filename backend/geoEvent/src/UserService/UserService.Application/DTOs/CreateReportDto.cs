using System.ComponentModel.DataAnnotations;
using UserService.Domain.Enums;

namespace UserService.Application.DTOs;

public class CreateReportDto
{
    [Required]
    public ReportTargetType TargetType { get; set; }

    [Required]
    public int TargetId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Reason { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;
}
