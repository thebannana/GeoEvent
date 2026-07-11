using MessageService.Domain.Enums;

namespace MessageService.Domain.Entities;

public class ChatThread
{
    public long Id { get; private set; }
    public ChatThreadType Type { get; private set; }
    public string Title { get; private set; } = string.Empty;
    public int? EventId { get; private set; }
    public int? CreatedByUserId { get; private set; }
    public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? LastMessageAt { get; private set; }

    public ICollection<ChatThreadParticipant> Participants { get; private set; } = new List<ChatThreadParticipant>();
    public ICollection<ChatMessage> Messages { get; private set; } = new List<ChatMessage>();

    private ChatThread() { }

    public ChatThread(ChatThreadType type, string title, int? createdByUserId = null, int? eventId = null)
    {
        if (type == ChatThreadType.EventGroup && !eventId.HasValue)
            throw new InvalidOperationException("Event group threads must have an event ID.");

        if (type == ChatThreadType.Direct)
            title = string.Empty;

        Type = type;
        Title = NormalizeTitle(title, type);
        CreatedByUserId = createdByUserId;
        EventId = eventId;
        CreatedAt = DateTime.UtcNow;
    }

    public void Rename(string title)
    {
        if (Type == ChatThreadType.Direct)
            throw new InvalidOperationException("Direct threads cannot be renamed.");

        Title = NormalizeTitle(title, Type);
    }

    public void TouchLastMessageAt(DateTime? timestamp = null)
    {
        LastMessageAt = timestamp ?? DateTime.UtcNow;
    }

    private static string NormalizeTitle(string title, ChatThreadType type)
    {
        if (type == ChatThreadType.Direct)
            return string.Empty;

        var trimmed = (title ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(trimmed))
            throw new InvalidOperationException("Thread title cannot be empty.");

        if (trimmed.Length > 200)
            throw new InvalidOperationException("Thread title cannot exceed 200 characters.");

        return trimmed;
    }
}