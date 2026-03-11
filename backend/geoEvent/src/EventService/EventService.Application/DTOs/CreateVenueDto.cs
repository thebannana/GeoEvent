using System.ComponentModel.DataAnnotations;

namespace EventService.Application.DTOs;

public class CreateVenueDto
{
    [Required]
    [StringLength(200, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Address { get; set; }

    [Required]
    [Range(-90.0, 90.0)]
    public decimal Latitude { get; set; }

    [Required]
    [Range(-180.0, 180.0)]
    public decimal Longitude { get; set; }

    public int? CityId { get; set; }

    [StringLength(100)]
    public string? VenueType { get; set; }

    [StringLength(1000)]
    [Url]
    public string? WebsiteUrl { get; set; }

    [StringLength(30)]
    [Phone]
    public string? PhoneNumber { get; set; }

    [StringLength(2000)]
    public string? Description { get; set; }

    [StringLength(50)]
    public string? TimeZone { get; set; }

    [StringLength(10)]
    public string? Locale { get; set; }
}
