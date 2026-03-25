using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using NotificationService.Domain.Enums;
using NotificationService.IntegrationTests.Helpers;

namespace NotificationService.IntegrationTests.Tests;

public class InternalNotificationsTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public InternalNotificationsTests(CustomWebApplicationFactory factory) : base(factory) { }

    // -------------------------------------------------------------------------
    // POST /api/internal/notifications  — Create
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Create_ValidApiKey_Returns201WithNotification()
    {
        var client = Factory.CreateClient().WithApiKey();
        var response = await client.PostAsJsonAsync("/api/internal/notifications", new
        {
            userId = 1,
            type = "General",
            title = "Internal Alert",
            description = "Created internally"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("title").GetString().Should().Be("Internal Alert");
        body.GetProperty("userId").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task Create_InvalidApiKey_Returns401()
    {
        var client = Factory.CreateClient().WithApiKey("wrong-key");
        var response = await client.PostAsJsonAsync("/api/internal/notifications", new
        {
            userId = 1,
            type = "General",
            title = "Should Fail",
            description = "Bad key"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Create_NoApiKey_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/internal/notifications", new
        {
            userId = 1,
            type = "General",
            title = "Should Fail",
            description = "No key"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Create_MissingRequiredFields_Returns400()
    {
        var client = Factory.CreateClient().WithApiKey();
        var response = await client.PostAsJsonAsync("/api/internal/notifications", new
        {
            userId = 1
            // missing type, title, description
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Create_AllNotificationTypes_Return201()
    {
        var client = Factory.CreateClient().WithApiKey();
        var types = new[] { "Welcome", "General", "EventCreated", "TicketPurchased", "PaymentSucceeded" };

        foreach (var type in types)
        {
            var response = await client.PostAsJsonAsync("/api/internal/notifications", new
            {
                userId = 1,
                type,
                title = $"{type} title",
                description = $"{type} description"
            });
            response.StatusCode.Should().Be(HttpStatusCode.Created,
                because: $"type '{type}' should be accepted");
        }
    }

    // -------------------------------------------------------------------------
    // POST /api/internal/notifications/queue  — Queue
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Queue_ValidApiKey_Returns201WithQueueItem()
    {
        var client = Factory.CreateClient().WithApiKey();
        var response = await client.PostAsJsonAsync("/api/internal/notifications/queue", new
        {
            userId = 1,
            type = "General",
            payload = "{\"userId\":1,\"type\":\"General\",\"title\":\"T\",\"description\":\"D\"}",
            scheduledAt = DateTime.UtcNow.AddMinutes(5)
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Pending");
        body.GetProperty("userId").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task Queue_InvalidApiKey_Returns401()
    {
        var client = Factory.CreateClient().WithApiKey("bad-key");
        var response = await client.PostAsJsonAsync("/api/internal/notifications/queue", new
        {
            userId = 1,
            type = "General",
            payload = "{}"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Queue_NoApiKey_Returns401()
    {
        var response = await Factory.CreateClient()
            .PostAsJsonAsync("/api/internal/notifications/queue", new
            {
                userId = 1,
                type = "General",
                payload = "{}"
            });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Queue_WithoutScheduledAt_DefaultsToPending()
    {
        var client = Factory.CreateClient().WithApiKey();
        var response = await client.PostAsJsonAsync("/api/internal/notifications/queue", new
        {
            userId = 2,
            type = "Welcome",
            payload = "{\"userId\":2,\"type\":\"Welcome\",\"title\":\"Hi\",\"description\":\"Welcome\"}"
            // no scheduledAt — should default to UtcNow
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Pending");
    }
}
