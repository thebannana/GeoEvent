namespace UserService.Application.DTOs;

public class UpdateProfileDto
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? ImageUrl { get; set; }
    public int? CityId { get; set; }
}
