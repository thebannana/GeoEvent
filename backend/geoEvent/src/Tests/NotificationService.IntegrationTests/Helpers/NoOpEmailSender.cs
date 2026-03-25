using NotificationService.Application.Interfaces.Services;

namespace NotificationService.IntegrationTests.Helpers;

public class NoOpEmailSender : IEmailSender
{
    public Task SendAsync(string to, string subject, string htmlBody)
        => Task.CompletedTask;
}
