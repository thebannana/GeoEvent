using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using NotificationService.Application.DTOs;
using NotificationService.Application.Interfaces.Services;
using NotificationService.Domain.Entities;

namespace NotificationService.Infrastructure.Services;

public class NotificationProcessor : INotificationProcessor
{
    private readonly IEmailSender _emailSender;
    private readonly IServiceScopeFactory _scopeFactory;

    public NotificationProcessor(
        IEmailSender emailSender,
        IServiceScopeFactory scopeFactory)
    {
        _emailSender = emailSender;
        _scopeFactory = scopeFactory;
    }

    public async Task ProcessAsync(NotificationQueue item)
    {
        var dto = JsonSerializer.Deserialize<CreateNotificationDto>(item.Payload)
            ?? throw new InvalidOperationException(
                $"Cannot deserialize payload for queue item {item.QueueId}.");

        using var scope = _scopeFactory.CreateScope();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
        await notificationService.CreateNotificationAsync(dto);

        // TODO: send email via _emailSender when email address is available in payload
    }
}
