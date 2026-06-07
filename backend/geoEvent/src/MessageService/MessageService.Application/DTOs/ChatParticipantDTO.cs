namespace MessageService.Application.DTOs;

public class ChatParticipantDto
{
    public int UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public DateTime JoinedAt { get; set; }
    public bool IsOnline { get; set; }
    public DateTime? LastActiveAt { get; set; }
}