namespace MessageService.Domain.Entities;

public class ChatThreadParticipant
{
    public long ThreadId { get; private set; }
    public int UserId { get; private set; }
    public DateTime JoinedAt { get; private set; } = DateTime.UtcNow;
    public DateTime? LastReadAt { get; private set; }
    public DateTime? LeftAt { get; private set; }

    public ChatThread Thread { get; private set; } = default!;

    public bool IsActive => LeftAt == null;

    private ChatThreadParticipant() { }

    public ChatThreadParticipant(long threadId, int userId)
    {
        if (threadId <= 0)
            throw new InvalidOperationException("Thread ID must be greater than zero.");

        if (userId <= 0)
            throw new InvalidOperationException("User ID must be greater than zero.");

        ThreadId = threadId;
        UserId = userId;
        JoinedAt = DateTime.UtcNow;
    }

    public void MarkAsRead(DateTime? readAt = null)
    {
        if (!IsActive)
            throw new InvalidOperationException("Inactive participants cannot mark a thread as read.");

        LastReadAt = readAt ?? DateTime.UtcNow;
    }

    public void Leave()
    {
        if (!IsActive)
            return;

        LeftAt = DateTime.UtcNow;
    }

    public void Rejoin()
    {
        if (IsActive)
            return;

        LeftAt = null;
        JoinedAt = DateTime.UtcNow;
    }
}