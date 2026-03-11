using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
using MessageService.Domain.Entities;

namespace MessageService.Infrastructure.Services;

public class MessageServiceImpl : IMessageService
{
    private readonly IMessageRepository _repository;

    public MessageServiceImpl(IMessageRepository repository)
    {
        _repository = repository;
    }

    public async Task<ServiceResult<MessageResponseDto>> SendMessageAsync(
    int senderId, SendMessageDto dto)
    {
        if (senderId == dto.RecipientId)
            return ServiceResult<MessageResponseDto>.Fail(
                "You cannot send a message to yourself.");

        var message = new Message
        {
            SenderId = senderId,
            RecipientId = dto.RecipientId,
            EventId = dto.EventId,
            Content = dto.Content.Trim(),
            SentAt = DateTime.UtcNow
        };

        await _repository.AddAsync(message);
        return ServiceResult<MessageResponseDto>.Created(MapToDto(message));
    }


    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetConversationAsync(int userId, int otherUserId, MessageFilterDto filter)
    {
        var result = await _repository.GetConversationAsync(userId, otherUserId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(MapPagedResult(result));
    }

    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetInboxAsync(int userId, MessageFilterDto filter)
    {
        var result = await _repository.GetInboxAsync(userId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(MapPagedResult(result));
    }

    public async Task<ServiceResult<PagedResult<MessageResponseDto>>> GetSentAsync(int userId, MessageFilterDto filter)
    {
        var result = await _repository.GetSentAsync(userId, filter);
        return ServiceResult<PagedResult<MessageResponseDto>>.Ok(MapPagedResult(result));
    }

    public async Task<ServiceResult<MessageResponseDto>> MarkAsReadAsync(
    int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound(
                $"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId) || message.RecipientId != userId)
            return ServiceResult<MessageResponseDto>.Forbidden(
                "You are not the recipient of this message.");

        if (message.IsRead)
            return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));

        message.MarkAsRead();
        await _repository.UpdateAsync(message);
        return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));
    }


    public async Task<ServiceResult<int>> GetUnreadCountAsync(int userId)
    {
        var count = await _repository.GetUnreadCountAsync(userId);
        return ServiceResult<int>.Ok(count);
    }

    public async Task<ServiceResult<bool>> DeleteMessageAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<bool>.NotFound($"Message {messageId} not found.");

        if (!message.CanBeDeletedBy(userId))
            return ServiceResult<bool>.Forbidden(
                "You do not have access to this message.");

        message.SoftDeleteFor(userId);

        if (message.IsFullyDeleted())
            await _repository.DeleteAsync(message);
        else
            await _repository.UpdateAsync(message);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<List<ConversationSummaryDto>>> GetConversationSummariesAsync(
    int userId)
    {
        var summaries = await _repository.GetConversationSummariesAsync(userId);
        return ServiceResult<List<ConversationSummaryDto>>.Ok(summaries);
    }


    public async Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId, int otherUserId)
    {
        if (userId == otherUserId)
            return ServiceResult<bool>.Fail("Invalid operation.");

        await _repository.MarkAllAsReadAsync(userId, otherUserId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<MessageResponseDto>> EditMessageAsync(
    int messageId, int userId, EditMessageDto dto)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound(
                $"Message {messageId} not found.");

        if (!message.CanBeEditedBy(userId))
            return ServiceResult<MessageResponseDto>.Forbidden(
                "You can only edit your own messages.");

        message.Content = dto.Content.Trim();
        message.EditedAt = DateTime.UtcNow;
        await _repository.UpdateAsync(message);

        return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));
    }

    public async Task<ServiceResult<MessageResponseDto>> LikeMessageAsync(
    int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound(
                $"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId))
            return ServiceResult<MessageResponseDto>.Forbidden(
                "You do not have access to this message.");

        message.Like();
        await _repository.UpdateAsync(message);
        return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));
    }

    public async Task<ServiceResult<MessageResponseDto>> UnlikeMessageAsync(
        int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound(
                $"Message {messageId} not found.");

        if (!message.IsVisibleTo(userId))
            return ServiceResult<MessageResponseDto>.Forbidden(
                "You do not have access to this message.");

        message.Unlike();
        await _repository.UpdateAsync(message);
        return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));
    }

    private static MessageResponseDto MapToDto(Message m) => new()
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
        EditedAt = m.EditedAt
    };

    private static PagedResult<MessageResponseDto> MapPagedResult(PagedResult<Domain.Entities.Message> source) => new()
    {
        Items = source.Items.Select(MapToDto),
        TotalCount = source.TotalCount,
        Page = source.Page,
        PageSize = source.PageSize
    };
}
