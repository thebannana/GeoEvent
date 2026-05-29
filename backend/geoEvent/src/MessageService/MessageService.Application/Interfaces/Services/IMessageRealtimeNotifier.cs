using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IMessageRealtimeNotifier
{
    Task MessageCreatedAsync(MessageResponseDto message, int senderId, int recipientId);
    Task MessageUpdatedAsync(MessageResponseDto message, int senderId, int recipientId);
    Task MessageLikedAsync(MessageResponseDto message, int senderId, int recipientId);
    Task MessageUnlikedAsync(MessageResponseDto message, int senderId, int recipientId);
    Task MessageReadAsync(MessageResponseDto message, int senderId, int recipientId);
    Task MessageDeletedAsync(int messageId, int senderId, int recipientId);
    Task ConversationReadAllAsync(int readerUserId, int otherUserId);
}