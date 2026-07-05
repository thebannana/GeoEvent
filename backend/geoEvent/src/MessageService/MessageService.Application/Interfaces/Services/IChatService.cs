using MessageService.Application.Common;
using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IChatService
{
    Task AddUserToEventThreadAsync(int eventId, int userId, int? addedByUserId = null);
    Task<ServiceResult<UnreadCountDto>> GetUnreadCountAsync(int userId);
    Task HandleDeletedUserAsync(int userId);
    Task RemoveUserFromEventThreadAsync(int eventId, int userId);
    Task<ServiceResult<ChatThreadSummaryDto>> OpenDirectThreadAsync(int userId, int otherUserId);

    Task<ServiceResult<PagedResult<ChatThreadSummaryDto>>> GetThreadsAsync(
        int userId,
        ChatThreadsFilterDto filter);

    Task<ServiceResult<ChatThreadDetailDto>> GetThreadDetailAsync(long threadId, int userId);

    Task<ServiceResult<PagedResult<ChatMessageDto>>> GetMessagesAsync(
        long threadId,
        int userId,
        ChatMessagesFilterDto filter);

    Task<ServiceResult<ChatMessageDto>> SendMessageAsync(long threadId, int userId, SendThreadMessageDto dto);
    Task<ServiceResult<ChatMessageDto>> EditMessageAsync(long messageId, int userId, EditChatMessageDto dto);
    Task<ServiceResult<bool>> DeleteMessageAsync(long messageId, int userId);
    Task<ServiceResult<ChatMessageDto>> LikeMessageAsync(long messageId, int userId);
    Task<ServiceResult<ChatMessageDto>> UnlikeMessageAsync(long messageId, int userId);
    Task<ServiceResult<bool>> MarkThreadReadAsync(long threadId, int userId);
    Task<ServiceResult<PagedResult<ChatParticipantDto>>> GetParticipantsAsync(long threadId, int userId, int page, int pageSize);
    Task<ServiceResult<bool>> LeaveThreadAsync(long threadId, int userId);
    Task<bool> IsParticipantAsync(long threadId, int userId);
    Task SetUserOnlineAsync(int userId, bool isOnline);
}