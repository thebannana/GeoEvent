using MessageService.Application.Common;
using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IMessageService
{
    Task<ServiceResult<MessageResponseDto>> SendMessageAsync(int senderId, SendMessageDto dto);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetConversationAsync(int userId, int otherUserId, MessageFilterDto filter);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetInboxAsync(int userId, MessageFilterDto filter);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetSentAsync(int userId, MessageFilterDto filter);
    Task<ServiceResult<List<ConversationSummaryDto>>> GetConversationSummariesAsync(int userId);
    Task<ServiceResult<MessageResponseDto>> MarkAsReadAsync(int messageId, int userId);
    Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId, int otherUserId);
    Task<ServiceResult<int>> GetUnreadCountAsync(int userId);
    Task<ServiceResult<MessageResponseDto>> EditMessageAsync(int messageId, int userId, EditMessageDto dto);
    Task<ServiceResult<bool>> DeleteMessageAsync(int messageId, int userId);
    Task<ServiceResult<MessageResponseDto>> LikeMessageAsync(int messageId, int userId);
    Task<ServiceResult<MessageResponseDto>> UnlikeMessageAsync(int messageId, int userId);
}
