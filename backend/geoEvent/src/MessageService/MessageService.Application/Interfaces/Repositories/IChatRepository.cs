using MessageService.Application.Common;
using MessageService.Domain.Entities;

namespace MessageService.Application.Interfaces.Repositories;

public interface IChatRepository
{
    Task<int> GetThreadUnreadCountAsync(long threadId, int userId);
    Task<int> GetUnreadCountAsync(int userId);

    Task<ChatThread?> GetThreadByIdAsync(long threadId);
    Task<ChatThread?> GetDirectThreadAsync(int userA, int userB);
    Task<ChatThread?> GetDirectThreadIncludingInactiveAsync(int userA, int userB);
    Task<ChatThread?> GetEventGroupThreadAsync(int eventId);
    Task<ChatThread> AddThreadAsync(ChatThread thread);
    Task UpdateThreadAsync(ChatThread thread);

    Task<bool> IsParticipantAsync(long threadId, int userId);
    Task<ChatThreadParticipant?> GetParticipantAsync(long threadId, int userId);
    Task AddParticipantAsync(ChatThreadParticipant participant);
    Task UpdateParticipantAsync(ChatThreadParticipant participant);
    Task<List<ChatThreadParticipant>> GetParticipantsAsync(long threadId);

    Task<ChatMessage?> GetMessageByIdAsync(long messageId);
    Task<PagedResult<ChatMessage>> GetMessagesAsync(long threadId, int page, int pageSize);
    Task<ChatMessage> AddMessageAsync(ChatMessage message);
    Task UpdateMessageAsync(ChatMessage message);

    Task<bool> HasMessageLikeAsync(long messageId, int userId);
    Task<ChatMessageLike?> GetMessageLikeAsync(long messageId, int userId);
    Task AddMessageLikeAsync(ChatMessageLike like);
    Task RemoveMessageLikeAsync(ChatMessageLike like);

    Task<List<ChatThreadParticipant>> GetUserParticipationsAsync(int userId);
    Task<List<ChatMessage>> GetMessagesBySenderAsync(int userId);
    Task<List<ChatThread>> GetUserThreadsAsync(int userId);
}