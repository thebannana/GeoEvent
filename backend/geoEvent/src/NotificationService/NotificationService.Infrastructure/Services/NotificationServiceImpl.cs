using Microsoft.Extensions.Logging;
using NotificationService.Application.Common;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Repositories;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Exceptions;

namespace NotificationService.Infrastructure.Services;

public class NotificationServiceImpl : INotificationService
{
    private readonly INotificationRepository repo;
    private readonly ILogger<NotificationServiceImpl> logger;

    public NotificationServiceImpl(
        INotificationRepository repo,
        ILogger<NotificationServiceImpl> logger)
    {
        this.repo = repo;
        this.logger = logger;
    }

    public async Task<ServiceResult<NotificationResponseDto>> GetNotificationAsync(
        int notificationId,
        int userId)
    {
        var notification = await repo.GetByIdAsync(notificationId);

        if (notification is null)
            return ServiceResult<NotificationResponseDto>.NotFound("Notification not found.");

        if (notification.UserId != userId)
            return ServiceResult<NotificationResponseDto>.Forbidden("Access denied.");

        return ServiceResult<NotificationResponseDto>.Ok(MapToDto(notification));
    }

    public async Task<ServiceResult<PagedResult<NotificationResponseDto>>> GetUserNotificationsAsync(
        int userId,
        NotificationFilterDto filter)
    {
        var result = await repo.GetUserNotificationsAsync(userId, filter);

        var mapped = new PagedResult<NotificationResponseDto>
        {
            Items = result.Items.Select(MapToDto),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };

        return ServiceResult<PagedResult<NotificationResponseDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<int>> GetUnreadCountAsync(int userId)
    {
        var count = await repo.GetUnreadCountAsync(userId);
        return ServiceResult<int>.Ok(count);
    }

    public async Task<ServiceResult<NotificationResponseDto>> CreateNotificationAsync(
        CreateNotificationDto dto)
    {
        var notification = new Notification
        {
            UserId = dto.UserId,
            Type = dto.Type,
            Title = dto.Title,
            Description = dto.Description,
            ImageUrl = dto.ImageUrl,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        var created = await repo.CreateAsync(notification);

        logger.LogInformation(
            "Created notification {NotificationId} for User {UserId}",
            created.NotificationId,
            dto.UserId);

        return ServiceResult<NotificationResponseDto>.Ok(MapToDto(created));
    }

    public async Task<ServiceResult<bool>> MarkAsReadAsync(int notificationId, int userId)
    {
        var notification = await repo.GetByIdAsync(notificationId);

        if (notification is null)
            return ServiceResult<bool>.NotFound("Notification not found.");

        if (notification.UserId != userId)
            return ServiceResult<bool>.Forbidden("Access denied.");

        if (notification.IsRead)
            throw new NotificationAlreadyReadException(notificationId);

        notification.MarkAsRead();
        await repo.UpdateAsync(notification);

        logger.LogInformation(
            "Marked notification {NotificationId} as read for User {UserId}",
            notificationId,
            userId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId)
    {
        await repo.MarkAllAsReadAsync(userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteNotificationAsync(int notificationId, int userId)
    {
        var notification = await repo.GetByIdAsync(notificationId);

        if (notification is null)
            return ServiceResult<bool>.NotFound("Notification not found.");

        if (notification.UserId != userId)
            return ServiceResult<bool>.Forbidden("Access denied.");

        await repo.DeleteAsync(notification);

        logger.LogInformation(
            "Deleted notification {NotificationId} for User {UserId}",
            notificationId,
            userId);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> DeleteAllNotificationsAsync(int userId)
    {
        await repo.DeleteAllAsync(userId);

        logger.LogInformation(
            "Deleted all notifications for User {UserId}",
            userId);

        return ServiceResult<bool>.Ok(true);
    }

    private static NotificationResponseDto MapToDto(Notification n) => new()
    {
        NotificationId = n.NotificationId,
        Type = n.Type.ToString(),
        Title = n.Title,
        Description = n.Description,
        ImageUrl = n.ImageUrl,
        IsRead = n.IsRead,
        UserId = n.UserId,
        CreatedAt = n.CreatedAt,
        ReadAt = n.ReadAt
    };
}