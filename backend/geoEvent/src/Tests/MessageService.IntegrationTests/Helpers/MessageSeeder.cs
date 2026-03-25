using MessageService.Domain.Entities;
using MessageService.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace MessageService.IntegrationTests.Helpers;

public static class MessageSeeder
{
    public static async Task<Message> SeedMessageAsync(
        IServiceProvider services,
        int senderId,
        int recipientId,
        string content = "Hello there!",
        bool isRead = false,
        int? eventId = null)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MessageDbContext>();

        var message = new Message
        {
            SenderId = senderId,
            RecipientId = recipientId,
            Content = content,
            IsRead = isRead,
            SentAt = DateTime.UtcNow,
            EventId = eventId
        };

        db.Messages.Add(message);
        await db.SaveChangesAsync();
        return message;
    }

    public static async Task<List<Message>> SeedConversationAsync(
        IServiceProvider services,
        int user1Id,
        int user2Id,
        int count = 5)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<MessageDbContext>();

        var messages = new List<Message>();
        for (var i = 0; i < count; i++)
        {
            var fromUser1 = i % 2 == 0;
            messages.Add(new Message
            {
                SenderId = fromUser1 ? user1Id : user2Id,
                RecipientId = fromUser1 ? user2Id : user1Id,
                Content = $"Message {i + 1}",
                IsRead = false,
                SentAt = DateTime.UtcNow.AddMinutes(-count + i)
            });
        }

        db.Messages.AddRange(messages);
        await db.SaveChangesAsync();
        return messages;
    }
}
