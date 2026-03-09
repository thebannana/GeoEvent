using MessageService.Application.Common;
using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IMessageService
{
    Task<ServiceResult<MessageResponseDto>> SendMessageAsync(int senderId, SendMessageDto dto);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetConversationAsync(int userId, int otherUserId, MessageFilterDto filter);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetInboxAsync(int userId, MessageFilterDto filter);
    Task<ServiceResult<PagedResult<MessageResponseDto>>> GetSentAsync(int userId, MessageFilterDto filter);
    Task<ServiceResult<MessageResponseDto>> MarkAsReadAsync(int messageId, int userId);
    Task<ServiceResult<int>> GetUnreadCountAsync(int userId);
    Task<ServiceResult<bool>> DeleteMessageAsync(int messageId, int userId);
}
