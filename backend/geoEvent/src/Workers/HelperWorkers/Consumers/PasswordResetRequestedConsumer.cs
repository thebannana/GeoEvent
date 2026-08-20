using GeoEvent.HelperWorkers.Interfaces;
using GeoEvent.HelperWorkers.Services;
using MassTransit;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Users;

namespace GeoEvent.HelperWorkers.Consumers;

public class PasswordResetRequestedConsumer : IConsumer<PasswordResetRequestedMessage>
{
    private readonly IEmailSender _emailSender;
    private readonly ILogger<PasswordResetRequestedConsumer> _logger;

    public PasswordResetRequestedConsumer(
        IEmailSender emailSender,
        ILogger<PasswordResetRequestedConsumer> logger)
    {
        _emailSender = emailSender;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<PasswordResetRequestedMessage> context)
    {
        var message = context.Message;

        _logger.LogInformation(
            "Processing PasswordResetRequestedMessage for UserId {UserId}, Email {Email}",
            message.UserId,
            message.Email);

        var resetLink = AppDeepLinkBuilder.BuildResetPasswordLink(message.Email, message.Token);

        var body = $"""
            <h2>Reset your password</h2>
            <p>You requested a password reset for your GeoEvent account.</p>
            <p><a href="{resetLink}">Reset password</a></p>
            <p>This token expires at {message.ExpiresAt:yyyy-MM-dd HH:mm:ss} UTC.</p>
            """;

        await _emailSender.SendAsync(message.Email, "GeoEvent password reset", body);
    }
}