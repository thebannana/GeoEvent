using NotificationService.Application.Common;
using NotificationService.Application.DTOs;

namespace NotificationService.Application.Interfaces.Services;

public interface INotificationService
{
    Task<ServiceResult<NotificationResponseDto>> GetNotificationAsync(int notificationId, int userId);
    Task<ServiceResult<PagedResult<NotificationResponseDto>>> GetUserNotificationsAsync(int userId, NotificationFilterDto filter);
    Task<ServiceResult<int>> GetUnreadCountAsync(int userId);
    Task<ServiceResult<NotificationResponseDto>> CreateNotificationAsync(CreateNotificationDto dto);
    Task<ServiceResult<bool>> MarkAsReadAsync(int notificationId, int userId);
    Task<ServiceResult<bool>> MarkAllAsReadAsync(int userId);
    Task<ServiceResult<bool>> DeleteNotificationAsync(int notificationId, int userId);
}