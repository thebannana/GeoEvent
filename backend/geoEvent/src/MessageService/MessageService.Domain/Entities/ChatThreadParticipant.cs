namespace MessageService.Domain.Entities;

public class ChatThreadParticipant
{
    public long ThreadId { get; set; }
    public int UserId { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastReadAt { get; set; }
    public DateTime? LeftAt { get; set; }

    public ChatThread Thread { get; set; } = default!;

    public bool IsActive => LeftAt == null;
}