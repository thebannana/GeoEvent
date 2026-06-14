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

    public Task<ChatThread?> GetThreadByIdAsync(long threadId) =>
        _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x => x.Id == threadId);

    public Task<ChatThread?> GetDirectThreadAsync(int userA, int userB) =>
        _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x =>
                x.Type == ChatThreadType.Direct &&
                x.Participants.Any(p => p.UserId == userA && p.LeftAt == null) &&
                x.Participants.Any(p => p.UserId == userB && p.LeftAt == null));

    public Task<ChatThread?> GetDirectThreadIncludingInactiveAsync(int userA, int userB) =>
        _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x =>
                x.Type == ChatThreadType.Direct &&
                x.Participants.Any(p => p.UserId == userA) &&
                x.Participants.Any(p => p.UserId == userB));

    public Task<ChatThread?> GetEventGroupThreadAsync(int eventId) =>
        _context.ChatThreads
            .Include(x => x.Participants)
            .FirstOrDefaultAsync(x => x.Type == ChatThreadType.EventGroup && x.EventId == eventId);

    public async Task<ChatThread> AddThreadAsync(ChatThread thread)
    {
        _context.ChatThreads.Add(thread);
        await _context.SaveChangesAsync();
        return thread;
    }

    public async Task<List<ChatThreadParticipant>> GetUserParticipationsAsync(int userId)
    {
        return await _context.ChatThreadParticipants
            .Where(p => p.UserId == userId)
            .ToListAsync();
    }

    public async Task<int> GetUnreadCountAsync(int userId)
    {
        return await
            (from p in _context.ChatThreadParticipants
             join m in _context.ChatMessages on p.ThreadId equals m.ThreadId
             where p.UserId == userId
                   && p.LeftAt == null
                   && m.SenderId != userId
                   && m.DeletedAt == null
                   && (p.LastReadAt == null || m.SentAt > p.LastReadAt)
             select m.Id)
            .CountAsync();
    }

    public async Task<int> GetThreadUnreadCountAsync(long threadId, int userId)
    {
        var participant = await _context.ChatThreadParticipants
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ThreadId == threadId && x.UserId == userId && x.LeftAt == null);

        if (participant == null)
            return 0;

        return await _context.ChatMessages
            .AsNoTracking()
            .Where(m =>
                m.ThreadId == threadId &&
                m.SenderId != userId &&
                m.DeletedAt == null &&
                (participant.LastReadAt == null || m.SentAt > participant.LastReadAt))
            .CountAsync();
    }

    public async Task<List<ChatMessage>> GetMessagesBySenderAsync(int userId)
    {
        return await _context.ChatMessages
            .Include(m => m.ReplyToMessage)
            .Where(m => m.SenderId == userId)
            .ToListAsync();
    }

    public async Task UpdateThreadAsync(ChatThread thread)
    {
        _context.ChatThreads.Update(thread);
        await _context.SaveChangesAsync();
    }

    public Task<bool> IsParticipantAsync(long threadId, int userId) =>
        _context.ChatThreadParticipants.AnyAsync(x =>
            x.ThreadId == threadId && x.UserId == userId && x.LeftAt == null);

    public Task<ChatThreadParticipant?> GetParticipantAsync(long threadId, int userId) =>
        _context.ChatThreadParticipants.FirstOrDefaultAsync(x =>
            x.ThreadId == threadId && x.UserId == userId);

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

    public Task<List<ChatThreadParticipant>> GetParticipantsAsync(long threadId) =>
        _context.ChatThreadParticipants
            .Where(x => x.ThreadId == threadId && x.LeftAt == null)
            .OrderBy(x => x.JoinedAt)
            .ToListAsync();

    public Task<ChatMessage?> GetMessageByIdAsync(long messageId) =>
        _context.ChatMessages
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

    public Task<bool> HasMessageLikeAsync(long messageId, int userId) =>
        _context.ChatMessageLikes.AnyAsync(x => x.MessageId == messageId && x.UserId == userId);

    public Task<ChatMessageLike?> GetMessageLikeAsync(long messageId, int userId) =>
        _context.ChatMessageLikes.FirstOrDefaultAsync(x => x.MessageId == messageId && x.UserId == userId);

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

    public Task<List<ChatThread>> GetUserThreadsAsync(int userId) =>
        _context.ChatThreads
            .Include(x => x.Participants)
            .Where(x => x.Participants.Any(p => p.UserId == userId && p.LeftAt == null))
            .OrderByDescending(x => x.LastMessageAt ?? x.CreatedAt)
            .ToListAsync();
}