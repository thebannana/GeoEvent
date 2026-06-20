using MessageService.Application.Common;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Domain.Entities;
using MessageService.Domain.Enums;
using MessageService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MessageService.Infrastructure.Repositories;

public class ChatRepository : IChatRepository
{
    private readonly MessageDbContext _context;

    public ChatRepository(MessageDbContext context)
    {
        _context = context;
    }

    public async Task<ChatThread?> GetThreadByIdAsync(long threadId) =>
        await _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x => x.Id == threadId);

    public async Task<ChatThread?> GetDirectThreadAsync(int userA, int userB) =>
        await _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x =>
                x.Type == ChatThreadType.Direct &&
                x.Participants.Any(p => p.UserId == userA && p.LeftAt == null) &&
                x.Participants.Any(p => p.UserId == userB && p.LeftAt == null));

    public async Task<ChatThread?> GetDirectThreadIncludingInactiveAsync(int userA, int userB) =>
        await _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x =>
                x.Type == ChatThreadType.Direct &&
                x.Participants.Any(p => p.UserId == userA) &&
                x.Participants.Any(p => p.UserId == userB));

    public async Task<ChatThread?> GetEventGroupThreadAsync(int eventId) =>
        await _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x =>
                x.Type == ChatThreadType.EventGroup &&
                x.EventId == eventId);

    public async Task<ChatThread> AddThreadAsync(ChatThread thread)
    {
        _context.ChatThreads.Add(thread);
        await _context.SaveChangesAsync();
        return thread;
    }

    public async Task UpdateThreadAsync(ChatThread thread)
    {
        _context.ChatThreads.Update(thread);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> IsParticipantAsync(long threadId, int userId) =>
        await _context.ChatThreadParticipants
            .AnyAsync(x => x.ThreadId == threadId && x.UserId == userId && x.LeftAt == null);

    public async Task<ChatThreadParticipant?> GetParticipantAsync(long threadId, int userId) =>
        await _context.ChatThreadParticipants
            .FirstOrDefaultAsync(x => x.ThreadId == threadId && x.UserId == userId);

    public async Task AddParticipantAsync(ChatThreadParticipant participant)
    {
        _context.ChatThreadParticipants.Add(participant);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateParticipantAsync(ChatThreadParticipant participant)
    {
        _context.ChatThreadParticipants.Update(participant);
        await _context.SaveChangesAsync();
    }

    public async Task<List<ChatThreadParticipant>> GetParticipantsAsync(long threadId) =>
        await _context.ChatThreadParticipants
            .Where(x => x.ThreadId == threadId && x.LeftAt == null)
            .OrderBy(x => x.JoinedAt)
            .ToListAsync();

    public async Task<ChatMessage?> GetMessageByIdAsync(long messageId) =>
        await _context.ChatMessages
            .Include(x => x.ReplyToMessage)
            .FirstOrDefaultAsync(x => x.Id == messageId);

    public async Task<PagedResult<ChatMessage>> GetMessagesAsync(long threadId, int page, int pageSize)
    {
        var query = _context.ChatMessages
            .Include(x => x.ReplyToMessage)
            .Where(x => x.ThreadId == threadId && x.DeletedAt == null)
            .OrderByDescending(x => x.SentAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<ChatMessage>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<ChatMessage> AddMessageAsync(ChatMessage message)
    {
        _context.ChatMessages.Add(message);
        await _context.SaveChangesAsync();
        return message;
    }

    public async Task UpdateMessageAsync(ChatMessage message)
    {
        _context.ChatMessages.Update(message);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> HasMessageLikeAsync(long messageId, int userId) =>
        await _context.ChatMessageLikes.AnyAsync(x => x.MessageId == messageId && x.UserId == userId);

    public async Task<ChatMessageLike?> GetMessageLikeAsync(long messageId, int userId) =>
        await _context.ChatMessageLikes.FirstOrDefaultAsync(x => x.MessageId == messageId && x.UserId == userId);

    public async Task AddMessageLikeAsync(ChatMessageLike like)
    {
        _context.ChatMessageLikes.Add(like);
        await _context.SaveChangesAsync();
    }

    public async Task RemoveMessageLikeAsync(ChatMessageLike like)
    {
        _context.ChatMessageLikes.Remove(like);
        await _context.SaveChangesAsync();
    }

    public async Task<List<ChatThreadParticipant>> GetUserParticipationsAsync(int userId) =>
        await _context.ChatThreadParticipants
            .Where(x => x.UserId == userId)
            .ToListAsync();

    public async Task<List<ChatMessage>> GetMessagesBySenderAsync(int userId) =>
        await _context.ChatMessages
            .Include(x => x.ReplyToMessage)
            .Where(x => x.SenderId == userId)
            .ToListAsync();

    public async Task<List<ChatThread>> GetUserThreadsAsync(int userId) =>
        await _context.ChatThreads
            .Include(x => x.Participants)
            .Where(x => x.Participants.Any(p => p.UserId == userId && p.LeftAt == null))
            .OrderByDescending(x => x.LastMessageAt ?? x.CreatedAt)
            .ToListAsync();

    public async Task<int> GetUnreadCountAsync(int userId) =>
        await _context.ChatThreadParticipants
            .Where(p => p.UserId == userId && p.LeftAt == null)
            .Join(
                _context.ChatMessages,
                p => p.ThreadId,
                m => m.ThreadId,
                (p, m) => new { p, m })
            .CountAsync(x =>
                x.m.SenderId != userId &&
                x.m.DeletedAt == null &&
                (!x.p.LastReadAt.HasValue || x.m.SentAt > x.p.LastReadAt.Value));

    public async Task<int> GetThreadUnreadCountAsync(long threadId, int userId)
    {
        var participant = await _context.ChatThreadParticipants
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ThreadId == threadId && x.UserId == userId && x.LeftAt == null);

        if (participant is null)
            return 0;

        return await _context.ChatMessages
            .AsNoTracking()
            .CountAsync(m =>
                m.ThreadId == threadId &&
                m.SenderId != userId &&
                m.DeletedAt == null &&
                (!participant.LastReadAt.HasValue || m.SentAt > participant.LastReadAt.Value));
    }
}