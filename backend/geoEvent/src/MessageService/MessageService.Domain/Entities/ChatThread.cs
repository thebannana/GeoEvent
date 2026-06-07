namespace MessageService.Domain.Entities;

using MessageService.Domain.Enums;

public class ChatThread
{
    public long Id { get; set; }
    public ChatThreadType Type { get; set; }
    public string Title { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public int? CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastMessageAt { get; set; }

    public ICollection<ChatThreadParticipant> Participants { get; set; } = new List<ChatThreadParticipant>();
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}