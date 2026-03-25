using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using NotificationService.Domain.Enums;
using NotificationService.IntegrationTests.Helpers;

namespace NotificationService.IntegrationTests.Tests;

public class NotificationsTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    private const int User1 = 1;
    private const int User2 = 2;

    public NotificationsTests(CustomWebApplicationFactory factory) : base(factory) { }

    // -------------------------------------------------------------------------
    // GET /api/notifications
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetMyNotifications_NoNotifications_Returns200Empty()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetMyNotifications_WithNotifications_Returns200WithItems()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(2);
    }

    [Fact]
    public async Task GetMyNotifications_DoesNotReturnOtherUsersNotifications()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetMyNotifications_FilterByIsRead_ReturnsCorrectSubset()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);

        var unread = await client.GetAsync("/api/notifications?isRead=false");
        var unreadBody = await unread.Content.ReadFromJsonAsync<JsonElement>();
        unreadBody.GetProperty("totalCount").GetInt32().Should().Be(1);

        var read = await client.GetAsync("/api/notifications?isRead=true");
        var readBody = await read.Content.ReadFromJsonAsync<JsonElement>();
        readBody.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetMyNotifications_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/notifications/unread-count
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetUnreadCount_NoNotifications_Returns200WithZero()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications/unread-count");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetUnreadCount_WithUnreadNotifications_ReturnsCorrectCount()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications/unread-count");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(2);
    }

    [Fact]
    public async Task GetUnreadCount_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/notifications/unread-count");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // GET /api/notifications/{id}
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetById_OwnNotification_Returns200()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, title: "My Alert");
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/notifications/{n.NotificationId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("title").GetString().Should().Be("My Alert");
        body.GetProperty("notificationId").GetInt32().Should().Be(n.NotificationId);
    }

    [Fact]
    public async Task GetById_OtherUsersNotification_Returns403()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync($"/api/notifications/{n.NotificationId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetById_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/notifications/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/notifications/{id}/read
    // -------------------------------------------------------------------------

    [Fact]
    public async Task MarkAsRead_OwnUnreadNotification_Returns200()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/notifications/{n.NotificationId}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("Notification marked as read.");
    }

    [Fact]
    public async Task MarkAsRead_AfterCall_UnreadCountDecreases()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        await client.PatchAsync($"/api/notifications/{n.NotificationId}/read", null);
        var countResponse = await client.GetAsync("/api/notifications/unread-count");
        var body = await countResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task MarkAsRead_OtherUsersNotification_Returns403()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/notifications/{n.NotificationId}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task MarkAsRead_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync("/api/notifications/99999/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task MarkAsRead_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PatchAsync("/api/notifications/1/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // PATCH /api/notifications/read-all
    // -------------------------------------------------------------------------

    [Fact]
    public async Task MarkAllAsRead_Returns200()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync("/api/notifications/read-all", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("All notifications marked as read.");
    }

    [Fact]
    public async Task MarkAllAsRead_AfterCall_UnreadCountIsZero()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        await client.PatchAsync("/api/notifications/read-all", null);
        var countResponse = await client.GetAsync("/api/notifications/unread-count");
        var body = await countResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task MarkAllAsRead_DoesNotAffectOtherUsersNotifications()
    {
        await NotificationSeeder.SeedNotificationAsync(Factory.Services, User2, isRead: false);
        var client = Factory.CreateClient().WithAuth(User1);
        await client.PatchAsync("/api/notifications/read-all", null);

        // User2's notification should still be unread
        var client2 = Factory.CreateClient().WithAuth(User2);
        var countResponse = await client2.GetAsync("/api/notifications/unread-count");
        var body = await countResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("unreadCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task MarkAllAsRead_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PatchAsync("/api/notifications/read-all", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // DELETE /api/notifications/{id}
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Delete_OwnNotification_Returns204()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync($"/api/notifications/{n.NotificationId}");
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task Delete_AfterCall_NotificationNoLongerReturned()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1);
        var client = Factory.CreateClient().WithAuth(User1);
        await client.DeleteAsync($"/api/notifications/{n.NotificationId}");
        var getResponse = await client.GetAsync($"/api/notifications/{n.NotificationId}");
        getResponse.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Delete_OtherUsersNotification_Returns403()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User2);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync($"/api/notifications/{n.NotificationId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Delete_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.DeleteAsync("/api/notifications/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Delete_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().DeleteAsync("/api/notifications/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // Pagination
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetMyNotifications_Pagination_SecondPageReturnsCorrectSlice()
    {
        for (var i = 0; i < 25; i++)
            await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1,
                title: $"Notification {i + 1}");

        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.GetAsync("/api/notifications?page=2&pageSize=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("page").GetInt32().Should().Be(2);
        body.GetProperty("pageSize").GetInt32().Should().Be(10);
        body.GetProperty("totalCount").GetInt32().Should().Be(25);
        body.GetProperty("totalPages").GetInt32().Should().Be(3);
        body.GetProperty("items").GetArrayLength().Should().Be(10);
    }

    // -------------------------------------------------------------------------
    // MarkAsRead — already-read → 409
    // -------------------------------------------------------------------------

    [Fact]
    public async Task MarkAsRead_AlreadyRead_Returns409()
    {
        var n = await NotificationSeeder.SeedNotificationAsync(Factory.Services, User1, isRead: true);
        var client = Factory.CreateClient().WithAuth(User1);
        var response = await client.PatchAsync($"/api/notifications/{n.NotificationId}/read", null);
        response.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

}
