using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class UpdatePreferenceDto
{
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }

    [Range(0.0, 100.0)]
    public double Score { get; set; }
}
