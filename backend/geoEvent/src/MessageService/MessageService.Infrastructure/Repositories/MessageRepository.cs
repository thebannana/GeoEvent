using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Domain.Entities;
using MessageService.Domain.Enums;
using MessageService.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MessageService.Infrastructure.Repositories;

public class MessageRepository : IMessageRepository
{
    private readonly MessageDbContext _context;

    public MessageRepository(MessageDbContext context)
    {
        _context = context;
    }

    public async Task<Message?> GetByIdAsync(int messageId) =>
        await _context.Messages.FindAsync(messageId);

    public async Task<PagedResult<Message>> GetConversationAsync(
        int userId, int otherUserId, MessageFilterDto filter)
    {
        var query = _context.Messages
            .Where(m =>
                (m.SenderId == userId && m.RecipientId == otherUserId && !m.IsDeletedBySender) ||
                (m.SenderId == otherUserId && m.RecipientId == userId && !m.IsDeletedByRecipient));

        if (filter.EventId.HasValue)
            query = query.Where(m => m.EventId == filter.EventId.Value);

        query = filter.SortOrder == MessageSortOrder.Oldest
            ? query.OrderBy(m => m.SentAt)
            : query.OrderByDescending(m => m.SentAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Message>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<PagedResult<Message>> GetInboxAsync(int userId, MessageFilterDto filter)
    {
        var query = _context.Messages
            .Where(m => m.RecipientId == userId && !m.IsDeletedByRecipient);

        if (filter.IsRead.HasValue)
            query = query.Where(m => m.IsRead == filter.IsRead.Value);

        query = filter.SortOrder == MessageSortOrder.Oldest
            ? query.OrderBy(m => m.SentAt)
            : query.OrderByDescending(m => m.SentAt);


        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Message>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<PagedResult<Message>> GetSentAsync(int userId, MessageFilterDto filter)
    {
        var query = _context.Messages
            .Where(m => m.SenderId == userId && !m.IsDeletedBySender)
            .OrderByDescending(m => m.SentAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<Message>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<int> GetUnreadCountAsync(int userId) =>
        await _context.Messages
            .CountAsync(m => m.RecipientId == userId && !m.IsRead && !m.IsDeletedByRecipient);

    public async Task<Message> AddAsync(Message message)
    {
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();
        return message;
    }

    public async Task UpdateAsync(Message message)
    {
        _context.Messages.Update(message);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Message message)
    {
        _context.Messages.Remove(message);
        await _context.SaveChangesAsync();
    }

    public async Task<List<ConversationSummaryDto>> GetConversationSummariesAsync(int userId)
    {
        var messages = await _context.Messages
            .Where(m =>
                (m.SenderId == userId && !m.IsDeletedBySender) ||
                (m.RecipientId == userId && !m.IsDeletedByRecipient))
            .OrderByDescending(m => m.SentAt)
            .ToListAsync();

        return messages
            .GroupBy(m => m.SenderId == userId ? m.RecipientId : m.SenderId)
            .Select(g =>
            {
                var last = g.First();
                return new ConversationSummaryDto
                {
                    OtherUserId = g.Key,
                    LastMessageContent = last.Content,
                    LastMessageSentAt = last.SentAt,
                    UnreadCount = g.Count(m => m.RecipientId == userId && !m.IsRead),
                    IsLastMessageFromMe = last.SenderId == userId
                };
            })
            .ToList();
    }

    public async Task<bool> ExistsAsync(int messageId) =>
    await _context.Messages.AnyAsync(m => m.Id == messageId);

    public async Task MarkAllAsReadAsync(int userId, int otherUserId)
    {
        await _context.Messages
            .Where(m =>
                m.SenderId == otherUserId &&
                m.RecipientId == userId &&
                !m.IsRead &&
                !m.IsDeletedByRecipient)
            .ExecuteUpdateAsync(s => s
                .SetProperty(m => m.IsRead, true)
                .SetProperty(m => m.ReadAt, DateTime.UtcNow));
    }

}
