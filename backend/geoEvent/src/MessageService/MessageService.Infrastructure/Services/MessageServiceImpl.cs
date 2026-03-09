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

    public async Task<ServiceResult<MessageResponseDto>> SendMessageAsync(int senderId, SendMessageDto dto)
    {
        if (senderId == dto.RecipientId)
            return ServiceResult<MessageResponseDto>.Fail("You cannot send a message to yourself.");

        var message = new Message
        {
            SenderId = senderId,
            RecipientId = dto.RecipientId,
            Content = dto.Content,
            SentAt = DateTime.UtcNow
        };

        await _repository.AddAsync(message);
        return ServiceResult<MessageResponseDto>.Ok(MapToDto(message));
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

    public async Task<ServiceResult<MessageResponseDto>> MarkAsReadAsync(int messageId, int userId)
    {
        var message = await _repository.GetByIdAsync(messageId);
        if (message is null)
            return ServiceResult<MessageResponseDto>.NotFound($"Message {messageId} not found.");

        if (message.RecipientId != userId)
            return ServiceResult<MessageResponseDto>.Forbidden("You are not the recipient of this message.");

        message.IsRead = true;
        message.ReadAt = DateTime.UtcNow;
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

        if (message.SenderId == userId)
            message.IsDeletedBySender = true;
        else if (message.RecipientId == userId)
            message.IsDeletedByRecipient = true;
        else
            return ServiceResult<bool>.Forbidden("You do not have access to this message.");

        if (message.IsDeletedBySender && message.IsDeletedByRecipient)
            await _repository.DeleteAsync(message);
        else
            await _repository.UpdateAsync(message);

        return ServiceResult<bool>.Ok(true);
    }

    private static MessageResponseDto MapToDto(Message m) => new()
    {
        Id = m.Id,
        SenderId = m.SenderId,
        RecipientId = m.RecipientId,
        Content = m.Content,
        IsRead = m.IsRead,
        SentAt = m.SentAt,
        ReadAt = m.ReadAt
    };

    private static PagedResult<MessageResponseDto> MapPagedResult(PagedResult<Domain.Entities.Message> source) => new()
    {
        Items = source.Items.Select(MapToDto),
        TotalCount = source.TotalCount,
        Page = source.Page,
        PageSize = source.PageSize
    };
}
