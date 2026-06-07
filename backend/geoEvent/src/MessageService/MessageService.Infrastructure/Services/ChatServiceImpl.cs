using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
using MessageService.Domain.Entities;
using MessageService.Domain.Enums;

namespace MessageService.Infrastructure.Services;

public class ChatServiceImpl : IChatService
{
    private readonly IChatRepository _repository;
    private readonly IUserDirectoryClient _userDirectoryClient;
    private readonly IEventDirectoryClient _eventDirectoryClient;
    private readonly IUserPresenceTracker _presenceTracker;
    private readonly IChatRealtimeNotifier _realtimeNotifier;

    public ChatServiceImpl(
        IChatRepository repository,
        IUserDirectoryClient userDirectoryClient,
        IEventDirectoryClient eventDirectoryClient,
        IUserPresenceTracker presenceTracker,
        IChatRealtimeNotifier realtimeNotifier)
    {
        _repository = repository;
        _userDirectoryClient = userDirectoryClient;
        _eventDirectoryClient = eventDirectoryClient;
        _presenceTracker = presenceTracker;
        _realtimeNotifier = realtimeNotifier;
    }

    public async Task<ServiceResult<ChatThreadSummaryDto>> OpenDirectThreadAsync(int userId, int otherUserId)
    {
        if (userId == otherUserId)
            return ServiceResult<ChatThreadSummaryDto>.Fail("You cannot open a chat with yourself.");

        var thread = await _repository.GetDirectThreadAsync(userId, otherUserId);
        if (thread == null)
        {
            thread = new ChatThread
            {
                Type = ChatThreadType.Direct,
                Title = string.Empty,
                CreatedByUserId = userId,
                CreatedAt = DateTime.UtcNow,
                Participants =
                {
                    new ChatThreadParticipant { UserId = userId, JoinedAt = DateTime.UtcNow },
                    new ChatThreadParticipant { UserId = otherUserId, JoinedAt = DateTime.UtcNow }
                }
            };

            thread = await _repository.AddThreadAsync(thread);
        }

        var dto = await MapThreadSummaryAsync(thread, userId);
        return ServiceResult<ChatThreadSummaryDto>.Ok(dto);
    }

    public async Task<ServiceResult<UnreadCountDto>> GetUnreadCountAsync(int userId)
    {
        var unreadCount = await _repository.GetUnreadCountAsync(userId);

        return ServiceResult<UnreadCountDto>.Ok(new UnreadCountDto
        {
            UnreadCount = unreadCount
        });
    }

    public async Task<ServiceResult<List<ChatThreadSummaryDto>>> GetThreadsAsync(int userId)
    {
        var threads = await _repository.GetUserThreadsAsync(userId);
        var result = new List<ChatThreadSummaryDto>();

        foreach (var thread in threads)
        {
            result.Add(await MapThreadSummaryAsync(thread, userId));
        }

        return ServiceResult<List<ChatThreadSummaryDto>>.Ok(result);
    }

    public async Task<ServiceResult<ChatThreadDetailDto>> GetThreadDetailAsync(long threadId, int userId)
    {
        var thread = await _repository.GetThreadByIdAsync(threadId);
        if (thread == null)
            return ServiceResult<ChatThreadDetailDto>.NotFound("Thread not found.");

        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<ChatThreadDetailDto>.Forbidden("You are not a participant of this thread.");

        EventChatInfoDto? eventInfo = null;
        if (thread.EventId.HasValue)
        {
            var evt = await _eventDirectoryClient.GetEventAsync(thread.EventId.Value);
            if (evt != null)
            {
                eventInfo = new EventChatInfoDto
                {
                    EventId = evt.EventId,
                    EventTitle = evt.Title,
                    StartDateTime = evt.StartDateTime,
                    VenueName = evt.VenueName,
                    IsOnline = evt.IsOnline
                };
            }
        }

        var participants = await BuildParticipantsAsync(threadId);

        return ServiceResult<ChatThreadDetailDto>.Ok(new ChatThreadDetailDto
        {
            ThreadId = thread.Id,
            Title = string.IsNullOrWhiteSpace(thread.Title)
                ? await ResolveDirectTitleAsync(thread, userId)
                : thread.Title,
            ThreadType = thread.Type.ToString(),
            EventId = thread.EventId,
            EventInfo = eventInfo,
            Participants = participants
        });
    }

    public async Task RemoveUserFromEventThreadAsync(int eventId, int userId)
    {
        var thread = await _repository.GetEventGroupThreadAsync(eventId);
        if (thread == null)
            return;

        var participant = await _repository.GetParticipantAsync(thread.Id, userId);
        if (participant == null || participant.LeftAt != null)
            return;

        participant.LeftAt = DateTime.UtcNow;
        await _repository.UpdateParticipantAsync(participant);
    }
    public async Task<ServiceResult<PagedResult<ChatMessageDto>>> GetMessagesAsync(long threadId, int userId, int page, int pageSize)
    {
        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<PagedResult<ChatMessageDto>>.Forbidden("You are not a participant of this thread.");

        var paged = await _repository.GetMessagesAsync(threadId, page, pageSize);
        var mapped = await MapMessagesAsync(paged.Items, userId);

        return ServiceResult<PagedResult<ChatMessageDto>>.Ok(new PagedResult<ChatMessageDto>
        {
            Items = mapped,
            TotalCount = paged.TotalCount,
            Page = paged.Page,
            PageSize = paged.PageSize
        });
    }

    public async Task<ServiceResult<ChatMessageDto>> SendMessageAsync(long threadId, int userId, SendThreadMessageDto dto)
    {
        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You are not a participant of this thread.");

        if (string.IsNullOrWhiteSpace(dto.Content))
            return ServiceResult<ChatMessageDto>.Fail("Message content cannot be empty.");

        if (dto.Content.Length > 4000)
            return ServiceResult<ChatMessageDto>.Fail("Message content cannot exceed 4000 characters.");

        if (dto.ReplyToMessageId.HasValue)
        {
            var replyTarget = await _repository.GetMessageByIdAsync(dto.ReplyToMessageId.Value);
            if (replyTarget == null || replyTarget.ThreadId != threadId)
                return ServiceResult<ChatMessageDto>.Fail("Reply target is invalid.");
        }

        var message = new ChatMessage
        {
            ThreadId = threadId,
            SenderId = userId,
            Content = dto.Content.Trim(),
            ReplyToMessageId = dto.ReplyToMessageId,
            SentAt = DateTime.UtcNow
        };

        message = await _repository.AddMessageAsync(message);

        var thread = await _repository.GetThreadByIdAsync(threadId);
        if (thread != null)
        {
            thread.LastMessageAt = message.SentAt;
            await _repository.UpdateThreadAsync(thread);
        }

        var mapped = await MapMessageAsync(message, userId);
        var participantIds = (await _repository.GetParticipantsAsync(threadId)).Select(x => x.UserId).ToList();
        await _realtimeNotifier.MessageCreatedAsync(mapped, participantIds);

        return ServiceResult<ChatMessageDto>.Created(mapped);
    }

    public async Task<ServiceResult<ChatMessageDto>> EditMessageAsync(long messageId, int userId, EditChatMessageDto dto)
    {
        var message = await _repository.GetMessageByIdAsync(messageId);
        if (message == null)
            return ServiceResult<ChatMessageDto>.NotFound("Message not found.");

        if (!message.CanEdit(userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You can only edit your own messages.");

        if (string.IsNullOrWhiteSpace(dto.Content))
            return ServiceResult<ChatMessageDto>.Fail("Edited content cannot be empty.");

        if (dto.Content.Length > 4000)
            return ServiceResult<ChatMessageDto>.Fail("Message content cannot exceed 4000 characters.");

        message.Edit(dto.Content);
        await _repository.UpdateMessageAsync(message);

        var mapped = await MapMessageAsync(message, userId);
        var participantIds = (await _repository.GetParticipantsAsync(message.ThreadId)).Select(x => x.UserId).ToList();
        await _realtimeNotifier.MessageUpdatedAsync(mapped, participantIds);

        return ServiceResult<ChatMessageDto>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> DeleteMessageAsync(long messageId, int userId)
    {
        var message = await _repository.GetMessageByIdAsync(messageId);
        if (message == null)
            return ServiceResult<bool>.NotFound("Message not found.");

        if (!message.CanDelete(userId))
            return ServiceResult<bool>.Forbidden("You can only delete your own messages.");

        message.SoftDelete();
        await _repository.UpdateMessageAsync(message);

        var participantIds = (await _repository.GetParticipantsAsync(message.ThreadId)).Select(x => x.UserId).ToList();
        await _realtimeNotifier.MessageDeletedAsync(message.ThreadId, message.Id, participantIds);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<ChatMessageDto>> LikeMessageAsync(long messageId, int userId)
    {
        var message = await _repository.GetMessageByIdAsync(messageId);
        if (message == null)
            return ServiceResult<ChatMessageDto>.NotFound("Message not found.");

        if (!await _repository.IsParticipantAsync(message.ThreadId, userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You are not a participant of this thread.");

        if (message.SenderId == userId)
            return ServiceResult<ChatMessageDto>.Fail("You cannot like your own message.");

        if (await _repository.HasMessageLikeAsync(messageId, userId))
            return ServiceResult<ChatMessageDto>.Ok(await MapMessageAsync(message, userId));

        await _repository.AddMessageLikeAsync(new ChatMessageLike
        {
            MessageId = messageId,
            UserId = userId
        });

        message.LikesCount++;
        await _repository.UpdateMessageAsync(message);

        var mapped = await MapMessageAsync(message, userId);
        await _realtimeNotifier.MessageLikedAsync(mapped);

        return ServiceResult<ChatMessageDto>.Ok(mapped);
    }

    public async Task<ServiceResult<ChatMessageDto>> UnlikeMessageAsync(long messageId, int userId)
    {
        var message = await _repository.GetMessageByIdAsync(messageId);
        if (message == null)
            return ServiceResult<ChatMessageDto>.NotFound("Message not found.");

        if (!await _repository.IsParticipantAsync(message.ThreadId, userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You are not a participant of this thread.");

        var like = await _repository.GetMessageLikeAsync(messageId, userId);
        if (like != null)
        {
            await _repository.RemoveMessageLikeAsync(like);
            message.LikesCount = Math.Max(0, message.LikesCount - 1);
            await _repository.UpdateMessageAsync(message);
        }

        var mapped = await MapMessageAsync(message, userId);
        await _realtimeNotifier.MessageLikedAsync(mapped);

        return ServiceResult<ChatMessageDto>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> MarkThreadReadAsync(long threadId, int userId)
    {
        var participant = await _repository.GetParticipantAsync(threadId, userId);
        if (participant == null || participant.LeftAt != null)
            return ServiceResult<bool>.Forbidden("You are not a participant of this thread.");

        participant.LastReadAt = DateTime.UtcNow;
        await _repository.UpdateParticipantAsync(participant);
        await _realtimeNotifier.ThreadReadAsync(threadId, userId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<List<ChatParticipantDto>>> GetParticipantsAsync(long threadId, int userId)
    {
        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<List<ChatParticipantDto>>.Forbidden("You are not a participant of this thread.");

        return ServiceResult<List<ChatParticipantDto>>.Ok(await BuildParticipantsAsync(threadId));
    }

    public Task<bool> IsParticipantAsync(long threadId, int userId) =>
        _repository.IsParticipantAsync(threadId, userId);

    public async Task SetUserOnlineAsync(int userId, bool isOnline)
    {
        if (isOnline)
            await _presenceTracker.SetOnlineAsync(userId);
        else
            await _presenceTracker.SetOfflineAsync(userId);
    }

    public async Task AddUserToEventThreadAsync(int eventId, int userId)
    {
        var thread = await _repository.GetEventGroupThreadAsync(eventId);

        if (thread == null)
        {
            var evt = await _eventDirectoryClient.GetEventAsync(eventId);

            thread = new ChatThread
            {
                Type = ChatThreadType.EventGroup,
                EventId = eventId,
                Title = evt?.Title ?? $"Event {eventId}",
                CreatedByUserId = evt?.OrganizerId,
                CreatedAt = DateTime.UtcNow
            };

            thread = await _repository.AddThreadAsync(thread);

            if (evt?.OrganizerId is int organizerId)
            {
                await _repository.AddParticipantAsync(new ChatThreadParticipant
                {
                    ThreadId = thread.Id,
                    UserId = organizerId,
                    JoinedAt = DateTime.UtcNow
                });
            }
        }

        var existing = await _repository.GetParticipantAsync(thread.Id, userId);
        if (existing == null)
        {
            await _repository.AddParticipantAsync(new ChatThreadParticipant
            {
                ThreadId = thread.Id,
                UserId = userId,
                JoinedAt = DateTime.UtcNow
            });
        }
        else if (existing.LeftAt != null)
        {
            existing.LeftAt = null;
            existing.JoinedAt = DateTime.UtcNow;
            await _repository.UpdateParticipantAsync(existing);
        }
    }

    private async Task<List<ChatParticipantDto>> BuildParticipantsAsync(long threadId)
    {
        var participants = await _repository.GetParticipantsAsync(threadId);
        var users = await _userDirectoryClient.GetPublicUsersAsync(participants.Select(x => x.UserId));

        var result = new List<ChatParticipantDto>();

        foreach (var p in participants)
        {
            users.TryGetValue(p.UserId, out var user);

            result.Add(new ChatParticipantDto
            {
                UserId = p.UserId,
                DisplayName = user?.DisplayName ?? $"User {p.UserId}",
                Username = user?.Username ?? string.Empty,
                AvatarUrl = user?.ImageUrl,
                JoinedAt = p.JoinedAt,
                IsOnline = await _presenceTracker.IsOnlineAsync(p.UserId),
                LastActiveAt = await _presenceTracker.GetLastActiveAtAsync(p.UserId)
            });
        }

        return result;
    }
    public async Task HandleDeletedUserAsync(int userId)
    {
        var participations = await _repository.GetUserParticipationsAsync(userId);

        foreach (var participant in participations.Where(p => p.LeftAt == null))
        {
            participant.LeftAt = DateTime.UtcNow;
            await _repository.UpdateParticipantAsync(participant);
        }

        var messages = await _repository.GetMessagesBySenderAsync(userId);

        foreach (var message in messages.Where(m => m.DeletedAt == null))
        {
            message.SoftDelete();
            await _repository.UpdateMessageAsync(message);
        }
    }
    private async Task<ChatThreadSummaryDto> MapThreadSummaryAsync(ChatThread thread, int currentUserId)
    {
        if (thread.Type == ChatThreadType.Direct)
        {
            var otherUserId = thread.Participants
                .Where(x => x.UserId != currentUserId && x.LeftAt == null)
                .Select(x => x.UserId)
                .FirstOrDefault();

            var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { otherUserId });
            users.TryGetValue(otherUserId, out var otherUser);

            var messages = await _repository.GetMessagesAsync(thread.Id, 1, 1);
            var last = messages.Items.FirstOrDefault();

            return new ChatThreadSummaryDto
            {
                ThreadId = thread.Id,
                Title = otherUser?.DisplayName ?? $"User {otherUserId}",
                ThreadType = thread.Type.ToString(),
                EventId = thread.EventId,
                IsGroup = false,
                OtherUserId = otherUserId,
                OtherUserDisplayName = otherUser?.DisplayName,
                OtherUserAvatarUrl = otherUser?.ImageUrl,
                OtherUserIsOnline = await _presenceTracker.IsOnlineAsync(otherUserId),
                OtherUserLastActiveAt = await _presenceTracker.GetLastActiveAtAsync(otherUserId),
                LastMessageContent = last?.Content,
                LastMessageSentAt = last?.SentAt,
                UnreadCount = 0
            };
        }

        var paged = await _repository.GetMessagesAsync(thread.Id, 1, 1);
        var lastMessage = paged.Items.FirstOrDefault();

        return new ChatThreadSummaryDto
        {
            ThreadId = thread.Id,
            Title = thread.Title,
            ThreadType = thread.Type.ToString(),
            EventId = thread.EventId,
            IsGroup = true,
            LastMessageContent = lastMessage?.Content,
            LastMessageSentAt = lastMessage?.SentAt,
            UnreadCount = 0
        };
    }

    private async Task<string> ResolveDirectTitleAsync(ChatThread thread, int currentUserId)
    {
        var otherUserId = thread.Participants
            .Where(x => x.UserId != currentUserId && x.LeftAt == null)
            .Select(x => x.UserId)
            .FirstOrDefault();

        var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { otherUserId });
        return users.TryGetValue(otherUserId, out var user)
            ? user.DisplayName
            : $"User {otherUserId}";
    }

    private async Task<List<ChatMessageDto>> MapMessagesAsync(IEnumerable<ChatMessage> messages, int currentUserId)
    {
        var list = new List<ChatMessageDto>();
        foreach (var message in messages)
        {
            list.Add(await MapMessageAsync(message, currentUserId));
        }

        return list;
    }

    private async Task<ChatMessageDto> MapMessageAsync(ChatMessage message, int currentUserId)
    {
        var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { message.SenderId });

        users.TryGetValue(message.SenderId, out var sender);

        var isLiked = await _repository.HasMessageLikeAsync(message.Id, currentUserId);

        ChatReplyPreviewDto? reply = null;
        if (message.ReplyToMessage != null)
        {
            var replyUsers = await _userDirectoryClient.GetPublicUsersAsync(new[] { message.ReplyToMessage.SenderId });
            replyUsers.TryGetValue(message.ReplyToMessage.SenderId, out var replySender);

            reply = new ChatReplyPreviewDto
            {
                MessageId = message.ReplyToMessage.Id,
                SenderId = message.ReplyToMessage.SenderId,
                SenderDisplayName = replySender?.DisplayName ?? $"User {message.ReplyToMessage.SenderId}",
                Content = message.ReplyToMessage.Content
            };
        }

        return new ChatMessageDto
        {
            Id = message.Id,
            ThreadId = message.ThreadId,
            SenderId = message.SenderId,
            SenderDisplayName = sender?.DisplayName ?? $"User {message.SenderId}",
            SenderAvatarUrl = sender?.ImageUrl,
            Content = message.Content,
            SentAt = message.SentAt,
            EditedAt = message.EditedAt,
            DeletedAt = message.DeletedAt,
            LikesCount = message.LikesCount,
            IsLikedByMe = isLiked,
            ReplyTo = reply
        };
    }
}