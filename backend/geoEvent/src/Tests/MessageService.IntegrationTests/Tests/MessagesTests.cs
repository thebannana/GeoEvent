using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using MessageService.IntegrationTests.Helpers;
using Microsoft.Extensions.DependencyInjection;

namespace MessageService.IntegrationTests.Tests;

public class MessagesTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    private const int User1 = 1;
    private const int User2 = 2;
    private const int User3 = 3;

    public MessagesTests(CustomWebApplicationFactory factory) : base(factory) { }

    // -------------------------------------------------------------------------
    // POST /api/messages  — Send
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Send_ValidRequest_Returns201WithMessage()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User2,
            content = "Hello User2!"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("senderId").GetInt32().Should().Be(User1);
        body.GetProperty("recipientId").GetInt32().Should().Be(User2);
        body.GetProperty("content").GetString().Should().Be("Hello User2!");
    }

    [Fact]
    public async Task Send_WithEventId_Returns201()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User2,
            content = "Event-related message",
            eventId = 42
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("eventId").GetInt32().Should().Be(42);
    }

    [Fact]
    public async Task Send_ToSelf_Returns400()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User1,
            content = "Hello myself!"
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Send_EmptyContent_Returns400()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User2,
            content = ""
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Send_ContentExceeds4000Chars_Returns400()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User2,
            content = new string('x', 4001)
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Send_Unauthenticated_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/messages", new
        {
            recipientId = User2,
            content = "Hello!"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/messages/inbox
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetInbox_NoMessages_Returns200EmptyPagedResult()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/inbox");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetInbox_WithMessages_Returns200WithItems()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, "Hi User1!");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/inbox");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetInbox_DoesNotIncludeSentMessages()
    {
        // User1 sends to User2 — should not appear in User1's inbox
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "I sent this");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/inbox");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetInbox_FilterByIsRead_Returns200Filtered()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, "Unread", isRead: false);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, "Read", isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);

        var unread = await client.GetAsync("/api/messages/inbox?isRead=false");
        var unreadBody = await unread.Content.ReadFromJsonAsync<JsonElement>();
        unreadBody.GetProperty("totalCount").GetInt32().Should().Be(1);

        var read = await client.GetAsync("/api/messages/inbox?isRead=true");
        var readBody = await read.Content.ReadFromJsonAsync<JsonElement>();
        readBody.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetInbox_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/messages/inbox");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/messages/sent
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetSent_NoMessages_Returns200EmptyPagedResult()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/sent");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetSent_WithMessages_Returns200WithItems()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "Sent by User1");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/sent");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetSent_DoesNotIncludeReceivedMessages()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, "Received by User1");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/sent");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetSent_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/messages/sent");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/messages/conversation/{otherUserId}
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetConversation_WithMessages_Returns200WithItems()
    {
        await MessageSeeder.SeedConversationAsync(Factory.Services, User1, User2, count: 4);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(4);
    }

    [Fact]
    public async Task GetConversation_NoMessages_Returns200Empty()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetConversation_WithSelf_Returns400()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User1}");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetConversation_DoesNotIncludeOtherUsersMessages()
    {
        // User1-User2 conversation
        await MessageSeeder.SeedConversationAsync(Factory.Services, User1, User2, count: 3);
        // Unrelated message between User2 and User3
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User3);

        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(3);
    }

    [Fact]
    public async Task GetConversation_FilterByEventId_Returns200Filtered()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "Event msg", eventId: 10);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "No event msg");

        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}?eventId=10");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetConversation_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync($"/api/messages/conversation/{User2}");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/messages/conversations
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetConversations_NoMessages_Returns200EmptyList()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/conversations");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task GetConversations_WithMultipleConversations_Returns200WithSummaries()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "To User2");
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User3, "To User3");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/conversations");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(2);
    }

    [Fact]
    public async Task GetConversations_SummaryHasCorrectFields()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "Latest message");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/conversations");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var summary = body[0];
        summary.GetProperty("otherUserId").GetInt32().Should().Be(User2);
        summary.GetProperty("lastMessageContent").GetString().Should().Be("Latest message");
        summary.GetProperty("isLastMessageFromMe").GetBoolean().Should().BeTrue();
    }

    [Fact]
    public async Task GetConversations_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/messages/conversations");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/messages/unread-count
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetUnreadCount_NoMessages_Returns200WithZero()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/unread-count");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetUnreadCount_WithUnreadMessages_Returns200WithCorrectCount()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/messages/unread-count");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(2);
    }

    [Fact]
    public async Task GetUnreadCount_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/messages/unread-count");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/messages/{id}/read
    // -------------------------------------------------------------------------

    [Fact]
    public async Task MarkAsRead_ValidRecipient_Returns200WithIsReadTrue()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/messages/{msg.Id}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("isRead").GetBoolean().Should().BeTrue();
    }

    [Fact]
    public async Task MarkAsRead_AlreadyRead_Returns200Idempotent()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/messages/{msg.Id}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task MarkAsRead_NotRecipient_Returns403()
    {
        // User2 sends to User1, User3 tries to mark it read
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1);
        var client = Factory.CreateClient().WithAuth(User3);
        var response = await client.PatchAsync($"/api/messages/{msg.Id}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task MarkAsRead_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync("/api/messages/99999/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task MarkAsRead_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PatchAsync("/api/messages/1/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/messages/conversation/{otherUserId}/read-all
    // -------------------------------------------------------------------------

    [Fact]
    public async Task MarkAllAsRead_ValidRequest_Returns200()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/messages/conversation/{User2}/read-all", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("All messages marked as read.");
    }

    [Fact]
    public async Task MarkAllAsRead_AfterCall_UnreadCountIsZero()
    {
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        await client.PatchAsync($"/api/messages/conversation/{User2}/read-all", null);

        var countResponse = await client.GetAsync("/api/messages/unread-count");
        var body = await countResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task MarkAllAsRead_WithSelf_Returns400()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/messages/conversation/{User1}/read-all", null);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task MarkAllAsRead_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient()
            .PatchAsync($"/api/messages/conversation/{User2}/read-all", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/messages/{id}  — Edit
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Edit_OwnMessage_Returns200WithUpdatedContent()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2, "Original");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsJsonAsync($"/api/messages/{msg.Id}", new { content = "Edited!" });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("content").GetString().Should().Be("Edited!");
        body.TryGetProperty("editedAt", out _).Should().BeTrue();
    }

    [Fact]
    public async Task Edit_OtherUsersMessage_Returns403()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1, "User2s msg");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsJsonAsync($"/api/messages/{msg.Id}", new { content = "Hacked!" });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Edit_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsJsonAsync("/api/messages/99999", new { content = "Edit" });
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Edit_EmptyContent_Returns400()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsJsonAsync($"/api/messages/{msg.Id}", new { content = "" });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Edit_ContentExceeds4000Chars_Returns400()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsJsonAsync($"/api/messages/{msg.Id}",
            new { content = new string('x', 4001) });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Edit_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient()
            .PatchAsJsonAsync("/api/messages/1", new { content = "Edit" });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/messages/{id}
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Delete_AsSender_Returns204()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync($"/api/messages/{msg.Id}");
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task Delete_AsRecipient_Returns204()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User2);
        var response = await client.DeleteAsync($"/api/messages/{msg.Id}");
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task Delete_AsUnrelatedUser_Returns403()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User3);
        var response = await client.DeleteAsync($"/api/messages/{msg.Id}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Delete_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync("/api/messages/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Delete_ByBothParties_MessageFullyRemoved()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);

        // Sender deletes (soft-delete, record still exists)
        var firstDelete = await Factory.CreateClient().WithAuth(User1)
            .DeleteAsync($"/api/messages/{msg.Id}");
        firstDelete.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // Recipient deletes — this triggers full physical delete
        var secondDelete = await Factory.CreateClient().WithAuth(User2)
            .DeleteAsync($"/api/messages/{msg.Id}");
        secondDelete.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // Now the row is physically gone — a third attempt returns 404
        var thirdDelete = await Factory.CreateClient().WithAuth(User1)
            .DeleteAsync($"/api/messages/{msg.Id}");
        thirdDelete.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }


    [Fact]
    public async Task Delete_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().DeleteAsync("/api/messages/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // POST /api/messages/{id}/like
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Like_ValidMessage_Returns200WithIncrementedCount()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsync($"/api/messages/{msg.Id}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("likesCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task Like_OwnMessage_Returns400()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsync($"/api/messages/{msg.Id}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Like_UnrelatedMessage_Returns403()
    {
        // User1 sends to User2, User3 tries to like it
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User3);
        var response = await client.PostAsync($"/api/messages/{msg.Id}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Like_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PostAsync("/api/messages/99999/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Like_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PostAsync("/api/messages/1/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/messages/{id}/like  — Unlike
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Unlike_LikedMessage_Returns200WithDecrementedCount()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1);
        var client = Factory.CreateClient().WithAuth(User1);

        // Like first
        await client.PostAsync($"/api/messages/{msg.Id}/like", null);

        var response = await client.DeleteAsync($"/api/messages/{msg.Id}/like");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("likesCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task Unlike_NeverLiked_Returns200WithZeroCount()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User2, User1);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync($"/api/messages/{msg.Id}/like");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        // Unlike on 0 clamps to 0 — no error
        body.GetProperty("likesCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task Unlike_UnrelatedMessage_Returns403()
    {
        var msg = await MessageSeeder.SeedMessageAsync(Factory.Services, User1, User2);
        var client = Factory.CreateClient().WithAuth(User3);
        var response = await client.DeleteAsync($"/api/messages/{msg.Id}/like");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Unlike_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync("/api/messages/99999/like");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Unlike_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().DeleteAsync("/api/messages/1/like");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // Pagination
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetConversation_Pagination_SecondPageReturnsCorrectSlice()
    {
        // Seed 25 messages between User1 and User2
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<MessageService.Infrastructure.Persistence.MessageDbContext>();
        for (var i = 0; i < 25; i++)
        {
            db.Messages.Add(new MessageService.Domain.Entities.Message
            {
                SenderId = User1,
                RecipientId = User2,
                Content = $"Message {i + 1}",
                SentAt = DateTime.UtcNow.AddMinutes(-25 + i)
            });
        }
        await db.SaveChangesAsync();

        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}?page=2&pageSize=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("page").GetInt32().Should().Be(2);
        body.GetProperty("pageSize").GetInt32().Should().Be(10);
        body.GetProperty("totalCount").GetInt32().Should().Be(25);
        body.GetProperty("totalPages").GetInt32().Should().Be(3);
        body.GetProperty("items").GetArrayLength().Should().Be(10);
    }

    // -------------------------------------------------------------------------
    // Sort Order
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetConversation_SortOrderOldest_ReturnsAscendingOrder()
    {
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<MessageService.Infrastructure.Persistence.MessageDbContext>();
        for (var i = 0; i < 5; i++)
        {
            db.Messages.Add(new MessageService.Domain.Entities.Message
            {
                SenderId = User1,
                RecipientId = User2,
                Content = $"Message {i + 1}",
                SentAt = DateTime.UtcNow.AddMinutes(-5 + i) // ascending timestamps
            });
        }
        await db.SaveChangesAsync();

        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/messages/conversation/{User2}?sortOrder=Oldest");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        var timestamps = items.Select(i => i.GetProperty("sentAt").GetDateTime()).ToList();

        // Each timestamp should be less than or equal to the next
        for (var i = 0; i < timestamps.Count - 1; i++)
            timestamps[i].Should().BeOnOrBefore(timestamps[i + 1]);
    }

}
