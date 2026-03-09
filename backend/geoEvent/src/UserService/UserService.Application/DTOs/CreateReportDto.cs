using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class CreateReportDto
{
    [Required]
    [MaxLength(50)]
    public string TargetType { get; set; } = string.Empty;

    [Required]
    public int TargetId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Reason { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;
}
