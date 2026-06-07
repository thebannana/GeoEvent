using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IChatRealtimeNotifier
{
    Task MessageCreatedAsync(ChatMessageDto message, IReadOnlyCollection<int> participantUserIds);
    Task MessageUpdatedAsync(ChatMessageDto message, IReadOnlyCollection<int> participantUserIds);
    Task MessageDeletedAsync(long threadId, long messageId, IReadOnlyCollection<int> participantUserIds);
    Task MessageLikedAsync(ChatMessageDto message);
    Task ThreadReadAsync(long threadId, int userId);
}