using System.ComponentModel.DataAnnotations;

namespace UserService.Application.DTOs;

public class RateUserDto
{
    [Range(1, 5)]
    public int Value { get; set; }

    [MaxLength(1000)]
    public string? Comment { get; set; }
}