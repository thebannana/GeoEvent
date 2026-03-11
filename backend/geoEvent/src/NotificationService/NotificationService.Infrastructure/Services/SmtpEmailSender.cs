using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using NotificationService.Application.Interfaces.Services;

namespace NotificationService.Infrastructure.Services;

public class SmtpEmailSender : IEmailSender
{
    private readonly IConfiguration _config;

    public SmtpEmailSender(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendAsync(string to, string subject, string htmlBody)
    {
        var host = _config["Smtp:Host"]!;
        var port = int.Parse(_config["Smtp:Port"] ?? "587");
        var user = _config["Smtp:Username"]!;
        var pass = _config["Smtp:Password"]!;
        var from = _config["Smtp:From"]!;

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(user, pass),
            EnableSsl = true
        };

        var mail = new MailMessage(from, to, subject, htmlBody)
        {
            IsBodyHtml = true
        };

        await client.SendMailAsync(mail);
    }
}
