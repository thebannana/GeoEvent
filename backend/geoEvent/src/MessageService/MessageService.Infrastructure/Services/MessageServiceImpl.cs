using MassTransit;
using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
using MessageService.Domain.Entities;
using Shared.Contracts.Messages;

namespace MessageService.Infrastructure.Services;

public class MessageServiceImpl : IMessageService
{
    private readonly IMessageRepository _repository;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly IUserDirectoryClient _userDirectoryClient;
    private readonly IMessageRealtimeNotifier _realtimeNotifier;

    public MessageServiceImpl(
        IMessageRepository repository,
        IPublishEndpoint publishEndpoint,
        IUserDirectoryClient userDirectoryClient,
        IMessageRealtimeNotifier realtimeNotifier)
    {
        _repository = repository;
        _publishEndpoint = publishEndpoint;
        _userDirectoryClient = userDirectoryClient;
        _realtimeNotifier = realtimeNotifier;
    }

    public async Task<ServiceResult<MessageResponseDto>> SendMessageAsync(int senderId, SendMessageDto dto)
    {
        if (senderId == dto.RecipientId)
            return ServiceResult<MessageResponseDto>.Fail("You cannot send a message to yourself.");

        if (string.IsNullOrWhiteSpace(dto.Content))
            return ServiceResult<MessageResponseDto>.Fail("Message content cannot be empty.");

        if (dto.Content.Length > 4000)
            return ServiceResult<MessageResponseDto>.Fail("Message content cannot exceed 4000 characters.");

        var message = new Message
        {
            SenderId = senderId,
            RecipientId = dto.RecipientId,
            EventId = dto.EventId,
            Content = dto.Content.Trim(),
            SentAt = DateTime.UtcNow
        };

        await _repository.AddAsync(message);
        await _publishEndpoint.Publish(
            new NewMessageSentMessage(message.Id, message.SenderId, message.RecipientId, DateTime.UtcNow)
        );

        var mapped = await MapToDtoAsync(message);
        await _realtimeNotifier.MessageCreatedAsync(mapped, message.SenderId, message.RecipientId);

        return ServiceResult<MessageResponseDto>.Created(mapped);
    }

    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetConversationAsync(
        int userId,
        int otherUserId,
        MessageFilterDto filter)
    {
        if (userId == otherUserId)
            return ServiceResult<PagedResult<MessageResponseDto>>.Fail("Cannot retrieve conversation with yourself.");

        var result = await _repository.GetConversationAsync(userId, otherUserId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(await MapPagedResultAsync(result));
    }

    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetInboxAsync(int userId, MessageFilterDto filter)
    {
        var result = await _repository.GetInboxAsync(userId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(await MapPagedResultAsync(result));
    }

    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetSentAsync(int userId, MessageFilterDto filter)
    {
        var result = await _repository.GetSentAsync(userId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(await MapPagedResultAsync(result));
    }

    public async Task<ServiceResult<List<ConversationSummaryDto>>> GetConversationSummariesAsync(int userId)
    {
        var summaries = await _repository.GetConversationSummariesAsync(userId);
        var otherIds = summaries.Select(x => x.OtherUserId).Distinct().ToList();
        var users = await _userDirectoryClient.GetPublicUsersAsync(otherIds);

        var mapped = summaries.Select(s => new ConversationSummaryDto
        {
            OtherUserId = s.OtherUserId,
            OtherUserDisplayName = users.TryGetValue(s.OtherUserId, out var u)
                ? u.DisplayName
                : $"User {s.OtherUserId}",
            OtherUserAvatarUrl = users.TryGetValue(s.OtherUserId, out var u2)
                ? u2.ImageUrl
                : null,
            LastMessageContent = s.LastMessageContent,
            LastMessageSentAt = s.LastMessageSentAt,
            UnreadCount = s.UnreadCount,
            IsLastMessageFromMe = s.IsLastMessageFromMe
        }).ToList();

        return ServiceResult<List<ConversationSummaryDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<MessageResponseDto>> MarkAsReadAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound($"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId) || message.RecipientId != userId)
            return ServiceResult<MessageResponseDto>.Forbidden("You are not the recipient of this message.");

        if (!message.IsRead)
        {
            message.MarkAsRead();
            await _repository.UpdateAsync(message);
        }

        var mapped = await MapToDtoAsync(message);
        await _realtimeNotifier.MessageReadAsync(mapped, message.SenderId, message.RecipientId);

        return ServiceResult<MessageResponseDto>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId, int otherUserId)
    {
        if (userId == otherUserId)
            return ServiceResult<bool>.Fail("Invalid operation.");

        await _repository.MarkAllAsReadAsync(userId, otherUserId);
        await _realtimeNotifier.ConversationReadAllAsync(userId, otherUserId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<int>> GetUnreadCountAsync(int userId)
    {
        var count = await _repository.GetUnreadCountAsync(userId);
        return ServiceResult<int>.Ok(count);
    }

    public async Task<ServiceResult<MessageResponseDto>> EditMessageAsync(int messageId, int userId, EditMessageDto dto)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound($"Message {messageId} not found.");

        if (!message.CanBeEditedBy(userId))
            return ServiceResult<MessageResponseDto>.Forbidden("You can only edit your own messages.");

        if (string.IsNullOrWhiteSpace(dto.Content))
            return ServiceResult<MessageResponseDto>.Fail("Edited content cannot be empty.");

        if (dto.Content.Length > 4000)
            return ServiceResult<MessageResponseDto>.Fail("Message content cannot exceed 4000 characters.");

        message.Content = dto.Content.Trim();
        message.EditedAt = DateTime.UtcNow;
        await _repository.UpdateAsync(message);

        var mapped = await MapToDtoAsync(message);
        await _realtimeNotifier.MessageUpdatedAsync(mapped, message.SenderId, message.RecipientId);

        return ServiceResult<MessageResponseDto>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> DeleteMessageAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<bool>.NotFound($"Message {messageId} not found.");

        if (!message.CanBeDeletedBy(userId))
            return ServiceResult<bool>.Forbidden("You do not have access to this message.");

        message.SoftDeleteFor(userId);

        if (message.IsFullyDeleted)
            await _repository.DeleteAsync(message);
        else
            await _repository.UpdateAsync(message);

        await _realtimeNotifier.MessageDeletedAsync(messageId, message.SenderId, message.RecipientId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<MessageResponseDto>> LikeMessageAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound($"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId))
            return ServiceResult<MessageResponseDto>.Forbidden("You do not have access to this message.");

        if (message.SenderId == userId)
            return ServiceResult<MessageResponseDto>.Fail("You cannot like your own message.");

        message.Like();
        await _repository.UpdateAsync(message);

        var mapped = await MapToDtoAsync(message);
        await _realtimeNotifier.MessageLikedAsync(mapped, message.SenderId, message.RecipientId);

        return ServiceResult<MessageResponseDto>.Ok(mapped);
    }

    public async Task<ServiceResult<MessageResponseDto>> UnlikeMessageAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound($"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId))
            return ServiceResult<MessageResponseDto>.Forbidden("You do not have access to this message.");

        message.Unlike();
        await _repository.UpdateAsync(message);

        var mapped = await MapToDtoAsync(message);
        await _realtimeNotifier.MessageUnlikedAsync(mapped, message.SenderId, message.RecipientId);

        return ServiceResult<MessageResponseDto>.Ok(mapped);
    }

    public async Task SoftDeleteUserMessagesAsync(int userId)
    {
        await _repository.SoftDeleteAllForUserAsync(userId);
    }

    private async Task<MessageResponseDto> MapToDtoAsync(Message m)
    {
        var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { m.SenderId, m.RecipientId });
        users.TryGetValue(m.SenderId, out var sender);
        users.TryGetValue(m.RecipientId, out var recipient);

        return new MessageResponseDto
        {
            Id = m.Id,
            SenderId = m.SenderId,
            RecipientId = m.RecipientId,
            EventId = m.EventId,
            Content = m.Content,
            IsRead = m.IsRead,
            LikesCount = m.LikesCount,
            SentAt = m.SentAt,
            ReadAt = m.ReadAt,
            EditedAt = m.EditedAt,
            SenderDisplayName = sender?.DisplayName ?? $"User {m.SenderId}",
            SenderAvatarUrl = sender?.ImageUrl,
            RecipientDisplayName = recipient?.DisplayName ?? $"User {m.RecipientId}",
            RecipientAvatarUrl = recipient?.ImageUrl
        };
    }

    private async Task<PagedResult<MessageResponseDto>> MapPagedResultAsync(PagedResult<Message> source)
    {
        var ids = source.Items.SelectMany(m => new[] { m.SenderId, m.RecipientId }).Distinct().ToList();
        var users = await _userDirectoryClient.GetPublicUsersAsync(ids);

        return new PagedResult<MessageResponseDto>
        {
            Items = source.Items.Select(m => new MessageResponseDto
            {
                Id = m.Id,
                SenderId = m.SenderId,
                RecipientId = m.RecipientId,
                EventId = m.EventId,
                Content = m.Content,
                IsRead = m.IsRead,
                LikesCount = m.LikesCount,
                SentAt = m.SentAt,
                ReadAt = m.ReadAt,
                EditedAt = m.EditedAt,
                SenderDisplayName = users.TryGetValue(m.SenderId, out var sender)
                    ? sender.DisplayName
                    : $"User {m.SenderId}",
                SenderAvatarUrl = users.TryGetValue(m.SenderId, out var sender2)
                    ? sender2.ImageUrl
                    : null,
                RecipientDisplayName = users.TryGetValue(m.RecipientId, out var recipient)
                    ? recipient.DisplayName
                    : $"User {m.RecipientId}",
                RecipientAvatarUrl = users.TryGetValue(m.RecipientId, out var recipient2)
                    ? recipient2.ImageUrl
                    : null
            }).ToList(),
            TotalCount = source.TotalCount,
            Page = source.Page,
            PageSize = source.PageSize
        };
    }
}