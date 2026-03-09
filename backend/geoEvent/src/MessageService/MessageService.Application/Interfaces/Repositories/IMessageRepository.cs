using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Domain.Entities;

namespace MessageService.Application.Interfaces.Repositories;

public interface IMessageRepository
{
    Task<Message?> GetByIdAsync(int messageId);
    Task<PagedResult<Message>> GetConversationAsync(int userId, int otherUserId, MessageFilterDto filter);
    Task<PagedResult<Message>> GetInboxAsync(int userId, MessageFilterDto filter);
    Task<PagedResult<Message>> GetSentAsync(int userId, MessageFilterDto filter);
    Task<int> GetUnreadCountAsync(int userId);
    Task<Message> AddAsync(Message message);
    Task UpdateAsync(Message message);
    Task DeleteAsync(Message message);
    Task SaveChangesAsync();
}
