namespace MessageService.Application.DTOs;

public class PublicUserSummaryDto
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
}