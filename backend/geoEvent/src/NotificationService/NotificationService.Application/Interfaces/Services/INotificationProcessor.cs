using NotificationService.Domain.Entities;

namespace NotificationService.Application.Interfaces.Services;

public interface INotificationProcessor
{
    Task ProcessAsync(NotificationQueue queueItem);
}