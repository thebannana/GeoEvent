using MassTransit;
using MessageService.Application.Common;
using MessageService.Application.DTOs;
using MessageService.Application.Interfaces.Repositories;
using MessageService.Application.Interfaces.Services;
using MessageService.Domain.Entities;
using MessageService.Domain.Enums;
using Shared.Contracts.Chat;

namespace MessageService.Infrastructure.Services;

public class ChatServiceImpl : IChatService
{
    private readonly IChatRepository _repository;
    private readonly IUserDirectoryClient _userDirectoryClient;
    private readonly IEventDirectoryClient _eventDirectoryClient;
    private readonly IUserPresenceTracker _presenceTracker;
    private readonly IChatRealtimeNotifier _realtimeNotifier;
    private readonly IPublishEndpoint _publishEndpoint;

    public ChatServiceImpl(
        IChatRepository repository,
        IUserDirectoryClient userDirectoryClient,
        IEventDirectoryClient eventDirectoryClient,
        IUserPresenceTracker presenceTracker,
        IChatRealtimeNotifier realtimeNotifier,
        IPublishEndpoint publishEndpoint)
    {
        _repository = repository;
        _userDirectoryClient = userDirectoryClient;
        _eventDirectoryClient = eventDirectoryClient;
        _presenceTracker = presenceTracker;
        _realtimeNotifier = realtimeNotifier;
        _publishEndpoint = publishEndpoint;
    }

    public async Task<ServiceResult<ChatThreadSummaryDto>> OpenDirectThreadAsync(int userId, int otherUserId)
    {
        if (userId == otherUserId)
            return ServiceResult<ChatThreadSummaryDto>.Fail("You cannot open a chat with yourself.");

        var thread = await _repository.GetDirectThreadIncludingInactiveAsync(userId, otherUserId);

        if (thread == null)
        {
            thread = new ChatThread(ChatThreadType.Direct, string.Empty, userId);

            thread = await _repository.AddThreadAsync(thread);

            await _repository.AddParticipantAsync(new ChatThreadParticipant(thread.Id, userId));
            await _repository.AddParticipantAsync(new ChatThreadParticipant(thread.Id, otherUserId));

            thread = await _repository.GetThreadByIdAsync(thread.Id) ?? thread;
        }
        else
        {
            var currentParticipant = thread.Participants.FirstOrDefault(x => x.UserId == userId);
            if (currentParticipant != null && !currentParticipant.IsActive)
            {
                currentParticipant.Rejoin();
                await _repository.UpdateParticipantAsync(currentParticipant);
            }

            var otherParticipant = thread.Participants.FirstOrDefault(x => x.UserId == otherUserId);
            if (otherParticipant != null && !otherParticipant.IsActive)
            {
                otherParticipant.Rejoin();
                await _repository.UpdateParticipantAsync(otherParticipant);
            }

            thread = await _repository.GetThreadByIdAsync(thread.Id) ?? thread;
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

    public async Task<ServiceResult<PagedResult<ChatThreadSummaryDto>>>
        GetThreadsAsync(
            int userId,
            ChatThreadsFilterDto? filter)
    {
        filter ??= new ChatThreadsFilterDto();

        var page = filter.Page <= 0
            ? 1
            : filter.Page;

        var pageSize = filter.PageSize <= 0
            ? 20
            : Math.Min(filter.PageSize, 50);

        var searchTerm = string.IsNullOrWhiteSpace(filter.SearchTerm)
            ? null
            : filter.SearchTerm.Trim();

        var pagedThreads = await _repository.GetUserThreadsAsync(
            userId,
            page,
            pageSize,
            searchTerm,
            filter.UnreadOnly,
            skipPagination: !string.IsNullOrWhiteSpace(searchTerm));

        var threadItems = pagedThreads.Items.ToList();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var participantIds = threadItems
                .SelectMany(thread => thread.Participants)
                .Where(participant =>
                    participant.UserId != userId &&
                    participant.LeftAt == null)
                .Select(participant => participant.UserId)
                .Distinct()
                .ToList();

            var users = await _userDirectoryClient.GetPublicUsersAsync(
                participantIds);

            var matchingUserIds = users.Values
                .Where(user =>
                    user.Username.Contains(
                        searchTerm,
                        StringComparison.OrdinalIgnoreCase) ||
                    user.DisplayName.Contains(
                        searchTerm,
                        StringComparison.OrdinalIgnoreCase))
                .Select(user => user.UserId)
                .ToHashSet();

            threadItems = threadItems
                .Where(thread =>
                    thread.Title?.Contains(
                        searchTerm,
                        StringComparison.OrdinalIgnoreCase) == true ||
                    thread.Messages.Any(message =>
                        message.DeletedAt == null &&
                        message.Content.Contains(
                            searchTerm,
                            StringComparison.OrdinalIgnoreCase)) ||
                    thread.Participants.Any(participant =>
                        participant.LeftAt == null &&
                        matchingUserIds.Contains(
                            participant.UserId)))
                .ToList();

            var totalCount = threadItems.Count;

            threadItems = threadItems
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            pagedThreads.TotalCount = totalCount;
        }

        var mappedItems = new List<ChatThreadSummaryDto>(
            threadItems.Count);

        foreach (var thread in threadItems)
        {
            var dto = await MapThreadSummaryAsync(
                thread,
                userId);

            mappedItems.Add(dto);
        }

        var result = new PagedResult<ChatThreadSummaryDto>
        {
            Items = mappedItems,
            TotalCount = pagedThreads.TotalCount,
            Page = pagedThreads.Page,
            PageSize = pagedThreads.PageSize
        };

        return ServiceResult<PagedResult<ChatThreadSummaryDto>>.Ok(result);
    }

    public async Task<ServiceResult<bool>> LeaveThreadAsync(long threadId, int userId)
    {
        var thread = await _repository.GetThreadByIdAsync(threadId);
        if (thread == null)
            return ServiceResult<bool>.NotFound("Thread not found.");

        var participant = await _repository.GetParticipantAsync(threadId, userId);
        if (participant == null || !participant.IsActive)
            return ServiceResult<bool>.NotFound("You are not a participant of this thread.");

        participant.Leave();
        await _repository.UpdateParticipantAsync(participant);

        var ownMessagesInThread = await _repository.GetMessagesByThreadAndSenderAsync(threadId, userId);
        foreach (var message in ownMessagesInThread.Where(m => !m.IsDeleted))
        {
            message.SoftDelete();
            await _repository.UpdateMessageAsync(message);
        }

        var activeParticipants = await _repository.GetParticipantsAsync(threadId);
        var participantUserIds = activeParticipants
            .Select(x => x.UserId)
            .ToList();

        await _realtimeNotifier.ParticipantLeftAsync(threadId, userId, participantUserIds);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<ChatThreadDetailDto>> GetThreadDetailAsync(long threadId, int userId)
    {
        var thread = await _repository.GetThreadByIdAsync(threadId);
        if (thread == null)
            return ServiceResult<ChatThreadDetailDto>.NotFound("Thread not found.");

        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<ChatThreadDetailDto>.Forbidden("You are not a participant of this thread.");

        EventChatInfoDto? eventInfo = null;
        string? imageUrl = null;

        if (thread.EventId.HasValue)
        {
            var evt = await _eventDirectoryClient.GetEventAsync(thread.EventId.Value);
            if (evt != null)
            {
                imageUrl = evt.CoverImageUrl;

                eventInfo = new EventChatInfoDto
                {
                    EventId = evt.EventId,
                    EventTitle = evt.Title,
                    StartDateTime = EnsureUtc(evt.StartDateTime),
                    EndDateTime = EnsureUtc(evt.EndDateTime),
                    CoverImageUrl = evt.CoverImageUrl
                };
            }
        }

        var participants = await BuildParticipantsAsync(threadId);

        int? otherUserId = null;
        string? otherUserDisplayName = null;
        string? otherUserUsername = null;
        string? otherUserAvatarUrl = null;
        bool? otherUserIsOnline = null;
        DateTime? otherUserLastActiveAt = null;

        if (thread.Type == ChatThreadType.Direct)
        {
            otherUserId = thread.Participants
                .Where(x => x.UserId != userId && x.IsActive)
                .Select(x => (int?)x.UserId)
                .FirstOrDefault();

            if (otherUserId.HasValue)
            {
                var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { otherUserId.Value });
                users.TryGetValue(otherUserId.Value, out var otherUser);

                otherUserDisplayName = otherUser?.DisplayName;
                otherUserUsername = otherUser?.Username;
                otherUserAvatarUrl = otherUser?.ImageUrl;
                otherUserIsOnline = await _presenceTracker.IsOnlineAsync(otherUserId.Value);
                otherUserLastActiveAt = EnsureUtc(await _presenceTracker.GetLastActiveAtAsync(otherUserId.Value));
                imageUrl = otherUser?.ImageUrl;
            }
        }

        return ServiceResult<ChatThreadDetailDto>.Ok(new ChatThreadDetailDto
        {
            ThreadId = thread.Id,
            Title = thread.Type == ChatThreadType.Direct
                ? (!string.IsNullOrWhiteSpace(otherUserUsername)
                    ? otherUserUsername!
                    : otherUserDisplayName ?? $"User {otherUserId}")
                : thread.Title,
            ThreadType = thread.Type.ToString(),
            EventId = thread.EventId,
            ImageUrl = imageUrl,
            OtherUserId = otherUserId,
            OtherUserDisplayName = otherUserDisplayName,
            OtherUserUsername = otherUserUsername,
            OtherUserAvatarUrl = otherUserAvatarUrl,
            OtherUserIsOnline = otherUserIsOnline,
            OtherUserLastActiveAt = otherUserLastActiveAt,
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
        if (participant == null || !participant.IsActive)
            return;

        participant.Leave();
        await _repository.UpdateParticipantAsync(participant);

        var ownMessagesInThread = await _repository.GetMessagesByThreadAndSenderAsync(thread.Id, userId);
        foreach (var message in ownMessagesInThread.Where(m => !m.IsDeleted))
        {
            message.SoftDelete();
            await _repository.UpdateMessageAsync(message);
        }
    }

    public async Task<ServiceResult<PagedResult<ChatMessageDto>>> GetMessagesAsync(
        long threadId,
        int userId,
        ChatMessagesFilterDto? filter)
    {
        filter ??= new ChatMessagesFilterDto();

        var page = filter.Page <= 0 ? 1 : filter.Page;
        var pageSize = filter.PageSize <= 0 ? 30 : Math.Min(filter.PageSize, 100);

        if (!await _repository.IsParticipantAsync(threadId, userId))
        {
            return ServiceResult<PagedResult<ChatMessageDto>>.Forbidden(
                "You are not a participant of this thread.");
        }

        var pagedMessages = await _repository.GetMessagesAsync(threadId, page, pageSize);
        var mappedMessages = await MapMessagesAsync(pagedMessages.Items, userId);

        var result = new PagedResult<ChatMessageDto>
        {
            Items = mappedMessages,
            TotalCount = pagedMessages.TotalCount,
            Page = pagedMessages.Page,
            PageSize = pagedMessages.PageSize
        };

        return ServiceResult<PagedResult<ChatMessageDto>>.Ok(result);
    }

    public async Task<ServiceResult<ChatMessageDto>> SendMessageAsync(long threadId, int userId, SendThreadMessageDto dto)
    {
        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You are not a participant of this thread.");

        if (dto.ReplyToMessageId.HasValue)
        {
            var replyTarget = await _repository.GetMessageByIdAsync(dto.ReplyToMessageId.Value);
            if (replyTarget == null || replyTarget.ThreadId != threadId)
                return ServiceResult<ChatMessageDto>.Fail("Reply target is invalid.");
        }

        ChatMessage message;
        try
        {
            message = new ChatMessage(threadId, userId, dto.Content, dto.ReplyToMessageId);
        }
        catch (InvalidOperationException ex)
        {
            return ServiceResult<ChatMessageDto>.Fail(ex.Message);
        }

        message = await _repository.AddMessageAsync(message);

        var thread = await _repository.GetThreadByIdAsync(threadId);
        if (thread != null)
        {
            thread.TouchLastMessageAt(message.SentAt);
            await _repository.UpdateThreadAsync(thread);
        }

        var mapped = await MapMessageAsync(message, userId);
        var participants = await _repository.GetParticipantsAsync(threadId);
        var participantIds = participants.Select(x => x.UserId).ToList();

        await _realtimeNotifier.MessageCreatedAsync(mapped, participantIds);

        if (thread != null)
        {
            var senderUsers = await _userDirectoryClient.GetPublicUsersAsync(new[] { userId });
            senderUsers.TryGetValue(userId, out var sender);

            var senderDisplayName =
                !string.IsNullOrWhiteSpace(sender?.Username)
                    ? sender!.Username
                    : sender?.DisplayName ?? $"User {userId}";

            string threadTitle;
            string? threadImageUrl;

            if (thread.Type == ChatThreadType.Direct)
            {
                threadTitle = senderDisplayName;
                threadImageUrl = sender?.ImageUrl;
            }
            else
            {
                string? eventImageUrl = null;

                if (thread.EventId.HasValue)
                {
                    var evt = await _eventDirectoryClient.GetEventAsync(thread.EventId.Value);
                    if (evt != null)
                    {
                        threadTitle = evt.Title;
                        eventImageUrl = evt.CoverImageUrl;
                    }
                    else
                    {
                        threadTitle = thread.Title;
                    }
                }
                else
                {
                    threadTitle = thread.Title;
                }

                threadImageUrl = eventImageUrl;
            }

            await _publishEndpoint.Publish(new ChatMessageSentIntegrationEvent
            {
                ThreadId = thread.Id,
                ThreadTitle = threadTitle,
                ThreadImageUrl = threadImageUrl,
                SenderUserId = userId,
                SenderDisplayName = senderDisplayName,
                SenderAvatarUrl = sender?.ImageUrl,
                RecipientUserIds = participantIds.Where(x => x != userId).ToArray(),
                IsGroupThread = thread.Type != ChatThreadType.Direct,
                MessagePreview = BuildPreview(message.Content)
            });
        }

        return ServiceResult<ChatMessageDto>.Created(mapped);
    }

    public async Task<ServiceResult<ChatMessageDto>> EditMessageAsync(long messageId, int userId, EditChatMessageDto dto)
    {
        var message = await _repository.GetMessageByIdAsync(messageId);
        if (message == null)
            return ServiceResult<ChatMessageDto>.NotFound("Message not found.");

        if (!message.CanEdit(userId))
            return ServiceResult<ChatMessageDto>.Forbidden("You can only edit your own messages.");

        try
        {
            message.Edit(dto.Content);
        }
        catch (InvalidOperationException ex)
        {
            return ServiceResult<ChatMessageDto>.Fail(ex.Message);
        }

        await _repository.UpdateMessageAsync(message);

        var mapped = await MapMessageAsync(message, userId);
        var participantIds = (await _repository.GetParticipantsAsync(message.ThreadId))
            .Select(x => x.UserId)
            .ToList();

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

        if (message.IsDeleted)
            return ServiceResult<bool>.Conflict("Message is already deleted.");

        message.SoftDelete();
        await _repository.UpdateMessageAsync(message);

        var participantIds = (await _repository.GetParticipantsAsync(message.ThreadId))
            .Select(x => x.UserId)
            .ToList();

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

        ChatMessageLike like;
        try
        {
            like = new ChatMessageLike(messageId, userId);
        }
        catch (InvalidOperationException ex)
        {
            return ServiceResult<ChatMessageDto>.Fail(ex.Message);
        }

        await _repository.AddMessageLikeAsync(like);

        message.IncrementLikes();
        await _repository.UpdateMessageAsync(message);

        var mapped = await MapMessageAsync(message, userId);
        await _realtimeNotifier.MessageLikedAsync(mapped);

        var likerUsers = await _userDirectoryClient.GetPublicUsersAsync(new[] { userId });
        likerUsers.TryGetValue(userId, out var liker);

        var likedByDisplayName =
            !string.IsNullOrWhiteSpace(liker?.Username)
                ? liker!.Username
                : liker?.DisplayName ?? $"User {userId}";

        var thread = await _repository.GetThreadByIdAsync(message.ThreadId);

        string threadTitle = string.Empty;
        string? threadImageUrl = null;

        if (thread != null && thread.Type != ChatThreadType.Direct)
        {
            threadTitle = thread.Title;

            if (thread.EventId.HasValue)
            {
                var evt = await _eventDirectoryClient.GetEventAsync(thread.EventId.Value);
                if (evt != null)
                {
                    threadTitle = evt.Title;
                    threadImageUrl = evt.CoverImageUrl;
                }
            }
        }

        await _publishEndpoint.Publish(new ChatMessageLikedIntegrationEvent
        {
            ThreadId = message.ThreadId,
            ThreadTitle = threadTitle,
            ThreadImageUrl = threadImageUrl,
            MessageId = message.Id,
            MessageOwnerUserId = message.SenderId,
            LikedByUserId = userId,
            LikedByDisplayName = likedByDisplayName,
            LikedByAvatarUrl = liker?.ImageUrl,
            MessagePreview = BuildPreview(message.Content)
        });

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
            message.DecrementLikes();
            await _repository.UpdateMessageAsync(message);
        }

        var mapped = await MapMessageAsync(message, userId);
        await _realtimeNotifier.MessageLikedAsync(mapped);

        return ServiceResult<ChatMessageDto>.Ok(mapped);
    }

    public async Task<ServiceResult<bool>> MarkThreadReadAsync(long threadId, int userId)
    {
        var participant = await _repository.GetParticipantAsync(threadId, userId);
        if (participant == null || !participant.IsActive)
            return ServiceResult<bool>.Forbidden("You are not a participant of this thread.");

        participant.MarkAsRead();
        await _repository.UpdateParticipantAsync(participant);

        var participantIds = (await _repository.GetParticipantsAsync(threadId))
            .Select(x => x.UserId)
            .ToList();

        await _realtimeNotifier.ThreadReadAsync(threadId, userId, participantIds);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<PagedResult<ChatParticipantDto>>> GetParticipantsAsync(
        long threadId,
        int userId,
        int page,
        int pageSize)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 50);

        if (!await _repository.IsParticipantAsync(threadId, userId))
            return ServiceResult<PagedResult<ChatParticipantDto>>.Forbidden("You are not a participant of this thread.");

        var participants = await BuildParticipantsAsync(threadId);
        var totalCount = participants.Count;
        var pagedItems = participants
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return ServiceResult<PagedResult<ChatParticipantDto>>.Ok(
            new PagedResult<ChatParticipantDto>
            {
                Items = pagedItems,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            });
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

    public async Task AddUserToEventThreadAsync(int eventId, int userId, int? addedByUserId = null)
    {
        var thread = await _repository.GetEventGroupThreadAsync(eventId);
        var evt = await _eventDirectoryClient.GetEventAsync(eventId);

        if (thread == null)
        {
            try
            {
                thread = new ChatThread(
                    ChatThreadType.EventGroup,
                    evt?.Title ?? $"Event {eventId}",
                    evt?.OrganizerId,
                    eventId);
            }
            catch (InvalidOperationException)
            {
                return;
            }

            thread = await _repository.AddThreadAsync(thread);

            if (evt?.OrganizerId is int organizerId)
            {
                var organizerParticipant = await _repository.GetParticipantAsync(thread.Id, organizerId);
                if (organizerParticipant == null)
                {
                    await _repository.AddParticipantAsync(new ChatThreadParticipant(thread.Id, organizerId));
                }
                else if (!organizerParticipant.IsActive)
                {
                    organizerParticipant.Rejoin();
                    await _repository.UpdateParticipantAsync(organizerParticipant);
                }
            }
        }

        var existing = await _repository.GetParticipantAsync(thread.Id, userId);
        var wasAdded = false;

        if (existing == null)
        {
            await _repository.AddParticipantAsync(new ChatThreadParticipant(thread.Id, userId));
            wasAdded = true;
        }
        else if (!existing.IsActive)
        {
            existing.Rejoin();
            await _repository.UpdateParticipantAsync(existing);
            wasAdded = true;
        }

        if (!wasAdded)
            return;

        string addedByDisplayName = string.Empty;
        string? addedByAvatarUrl = null;

        if (addedByUserId.HasValue)
        {
            var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { addedByUserId.Value });
            users.TryGetValue(addedByUserId.Value, out var addedByUser);

            addedByDisplayName =
                !string.IsNullOrWhiteSpace(addedByUser?.Username)
                    ? addedByUser!.Username
                    : addedByUser?.DisplayName ?? $"User {addedByUserId.Value}";

            addedByAvatarUrl = addedByUser?.ImageUrl;
        }

        await _publishEndpoint.Publish(new ChatUserAddedToGroupIntegrationEvent
        {
            ThreadId = thread.Id,
            AddedUserId = userId,
            AddedByUserId = addedByUserId,
            AddedByDisplayName = addedByDisplayName,
            AddedByAvatarUrl = addedByAvatarUrl,
            RelatedEventId = eventId,
            GroupTitle = evt?.Title ?? thread.Title,
            GroupImageUrl = evt?.CoverImageUrl
        });
    }

    public async Task HandleDeletedUserAsync(int userId)
    {
        var participations = await _repository.GetUserParticipationsAsync(userId);

        foreach (var participant in participations.Where(p => p.IsActive))
        {
            participant.Leave();
            await _repository.UpdateParticipantAsync(participant);
        }

        var messages = await _repository.GetMessagesBySenderAsync(userId);

        foreach (var message in messages.Where(m => !m.IsDeleted))
        {
            message.SoftDelete();
            await _repository.UpdateMessageAsync(message);
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
                JoinedAt = EnsureUtc(p.JoinedAt),
                IsOnline = await _presenceTracker.IsOnlineAsync(p.UserId),
                LastActiveAt = EnsureUtc(await _presenceTracker.GetLastActiveAtAsync(p.UserId))
            });
        }

        return result;
    }

    private async Task<ChatThreadSummaryDto> MapThreadSummaryAsync(ChatThread thread, int currentUserId)
    {
        var unreadCount = await _repository.GetThreadUnreadCountAsync(thread.Id, currentUserId);
        var paged = await _repository.GetMessagesAsync(thread.Id, 1, 1);
        var last = paged.Items.FirstOrDefault();

        if (thread.Type == ChatThreadType.Direct)
        {
            var otherParticipant = thread.Participants
                .Where(x => x.UserId != currentUserId)
                .OrderBy(x => x.IsActive ? 0 : 1)
                .ThenBy(x => x.JoinedAt)
                .FirstOrDefault();

            var otherUserId = otherParticipant?.UserId;

            if (!otherUserId.HasValue)
            {
                return new ChatThreadSummaryDto
                {
                    ThreadId = thread.Id,
                    Title = "Direct chat",
                    ThreadType = thread.Type.ToString(),
                    EventId = thread.EventId,
                    IsGroup = false,
                    LastMessageContent = last?.Content,
                    LastMessageSentAt = EnsureUtc(last?.SentAt),
                    UnreadCount = unreadCount
                };
            }

            var users = await _userDirectoryClient.GetPublicUsersAsync(new[] { otherUserId.Value });
            users.TryGetValue(otherUserId.Value, out var otherUser);

            var resolvedTitle =
                !string.IsNullOrWhiteSpace(otherUser?.DisplayName)
                    ? otherUser!.DisplayName
                    : !string.IsNullOrWhiteSpace(otherUser?.Username)
                        ? otherUser!.Username
                        : $"User {otherUserId.Value}";

            return new ChatThreadSummaryDto
            {
                ThreadId = thread.Id,
                Title = resolvedTitle,
                ThreadType = thread.Type.ToString(),
                EventId = thread.EventId,
                ImageUrl = otherUser?.ImageUrl,
                IsGroup = false,
                OtherUserId = otherUserId.Value,
                OtherUserDisplayName = otherUser?.DisplayName,
                OtherUserUsername = otherUser?.Username,
                OtherUserAvatarUrl = otherUser?.ImageUrl,
                OtherUserIsOnline = await _presenceTracker.IsOnlineAsync(otherUserId.Value),
                OtherUserLastActiveAt = EnsureUtc(await _presenceTracker.GetLastActiveAtAsync(otherUserId.Value)),
                LastMessageContent = last?.Content,
                LastMessageSentAt = EnsureUtc(last?.SentAt),
                UnreadCount = unreadCount
            };
        }

        string? groupImageUrl = null;
        if (thread.EventId.HasValue)
        {
            var evt = await _eventDirectoryClient.GetEventAsync(thread.EventId.Value);
            groupImageUrl = evt?.CoverImageUrl;
        }

        return new ChatThreadSummaryDto
        {
            ThreadId = thread.Id,
            Title = thread.Title,
            ThreadType = thread.Type.ToString(),
            EventId = thread.EventId,
            ImageUrl = groupImageUrl,
            IsGroup = true,
            LastMessageContent = last?.Content,
            LastMessageSentAt = EnsureUtc(last?.SentAt),
            UnreadCount = unreadCount
        };
    }

    private async Task<List<ChatMessageDto>> MapMessagesAsync(IEnumerable<ChatMessage> messages, int currentUserId)
    {
        var list = new List<ChatMessageDto>();

        foreach (var message in messages)
            list.Add(await MapMessageAsync(message, currentUserId));

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
                SenderDisplayName = !string.IsNullOrWhiteSpace(replySender?.Username)
                    ? replySender.Username
                    : replySender?.DisplayName ?? $"User {message.ReplyToMessage.SenderId}",
                Content = message.ReplyToMessage.Content
            };
        }

        return new ChatMessageDto
        {
            Id = message.Id,
            ThreadId = message.ThreadId,
            SenderId = message.SenderId,
            SenderDisplayName = !string.IsNullOrWhiteSpace(sender?.Username)
                ? sender.Username
                : sender?.DisplayName ?? $"User {message.SenderId}",
            SenderAvatarUrl = sender?.ImageUrl,
            Content = message.Content,
            SentAt = EnsureUtc(message.SentAt),
            EditedAt = EnsureUtc(message.EditedAt),
            DeletedAt = EnsureUtc(message.DeletedAt),
            LikesCount = message.LikesCount,
            IsLikedByMe = isLiked,
            ReplyTo = reply
        };
    }

    private static string BuildPreview(string? content, int maxLength = 120)
    {
        if (string.IsNullOrWhiteSpace(content))
            return string.Empty;

        var normalized = content.Trim();
        return normalized.Length <= maxLength
            ? normalized
            : normalized[..maxLength];
    }

    private static DateTime EnsureUtc(DateTime value) =>
        value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

    private static DateTime? EnsureUtc(DateTime? value) =>
        value.HasValue ? EnsureUtc(value.Value) : null;
}