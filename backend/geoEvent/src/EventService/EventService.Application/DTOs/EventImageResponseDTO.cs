namespace EventService.Application.DTOs;

public class EventImageResponseDto
{
    public int ImageId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public bool IsCover { get; set; }
    public DateTime UploadedAt { get; set; }
}