using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using NotificationService.Domain.Enums;
using NotificationService.IntegrationTests.Helpers;

namespace NotificationService.IntegrationTests.Tests;

public class QueueTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public QueueTests(CustomWebApplicationFactory factory) : base(factory) { }

    // -------------------------------------------------------------------------
    // GET /api/queue  — Admin only
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetAll_AsAdmin_Returns200WithItems()
    {
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services);
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.GetAsync("/api/queue");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().BeGreaterThanOrEqualTo(2);
    }

    [Fact]
    public async Task GetAll_AsUser_Returns403()
    {
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.GetAsync("/api/queue");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetAll_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/queue");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetAll_FilterByStatus_ReturnsCorrectItems()
    {
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services, status: NotificationQueueStatus.Pending);
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services, status: NotificationQueueStatus.Sent);
        var client = Factory.CreateClient().WithAuth(1, "Admin");

        var response = await client.GetAsync("/api/queue?status=Pending");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        items.Should().AllSatisfy(i =>
            i.GetProperty("status").GetString().Should().Be("Pending"));
    }

    [Fact]
    public async Task GetAll_FilterByType_ReturnsCorrectItems()
    {
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services, type: NotificationType.Welcome);
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services, type: NotificationType.General);
        var client = Factory.CreateClient().WithAuth(1, "Admin");

        var response = await client.GetAsync("/api/queue?type=Welcome");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        items.Should().AllSatisfy(i =>
            i.GetProperty("type").GetString().Should().Be("Welcome"));
    }

    // -------------------------------------------------------------------------
    // GET /api/queue/{id}
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetById_AsAdmin_Returns200()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.GetAsync($"/api/queue/{item.QueueId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("queueId").GetInt32().Should().Be(item.QueueId);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.GetAsync("/api/queue/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetById_AsUser_Returns403()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services);
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.GetAsync($"/api/queue/{item.QueueId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetById_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().GetAsync("/api/queue/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // POST /api/queue  — Queue via Admin
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Queue_AsAdmin_Returns201()
    {
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsJsonAsync("/api/queue", new
        {
            userId = 1,
            type = "General",
            payload = "{\"userId\":1,\"type\":\"General\",\"title\":\"T\",\"description\":\"D\"}"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Pending");
    }

    [Fact]
    public async Task Queue_AsUser_Returns403()
    {
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.PostAsJsonAsync("/api/queue", new
        {
            userId = 1,
            type = "General",
            payload = "{}"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Queue_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PostAsJsonAsync("/api/queue", new
        {
            userId = 1,
            type = "General",
            payload = "{}"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // POST /api/queue/process
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Process_AsAdmin_Returns200AndProcessesPendingItems()
    {
        // Valid serialized CreateNotificationDto payload
        const string payload = "{\"userId\":1,\"type\":\"General\",\"title\":\"T\",\"description\":\"D\"}";
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services, payload: payload,
            scheduledAt: DateTime.UtcNow.AddMinutes(-1));

        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync("/api/queue/process?batchSize=10", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("Queue processed.");
    }

    [Fact]
    public async Task Process_AsUser_Returns403()
    {
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.PostAsync("/api/queue/process", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Process_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PostAsync("/api/queue/process", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // POST /api/queue/retry-failed
    // -------------------------------------------------------------------------

    [Fact]
    public async Task RetryFailed_AsAdmin_Returns200()
    {
        await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Failed, attemptCount: 1);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync("/api/queue/retry-failed", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("Failed items queued for retry.");
    }

    [Fact]
    public async Task RetryFailed_FailedItemsStatusChangedToRetrying()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Failed, attemptCount: 1);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        await client.PostAsync("/api/queue/retry-failed", null);

        var getResponse = await client.GetAsync($"/api/queue/{item.QueueId}");
        var body = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Retrying");
    }

    [Fact]
    public async Task RetryFailed_MaxAttemptsReached_ItemNotRetried()
    {
        // AttemptCount >= MaxAttempts — CanRetry is false
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Failed, attemptCount: 3);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        await client.PostAsync("/api/queue/retry-failed", null);

        var getResponse = await client.GetAsync($"/api/queue/{item.QueueId}");
        var body = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        // Should remain Failed — not retried
        body.GetProperty("status").GetString().Should().Be("Failed");
    }

    [Fact]
    public async Task RetryFailed_AsUser_Returns403()
    {
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.PostAsync("/api/queue/retry-failed", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task RetryFailed_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PostAsync("/api/queue/retry-failed", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // POST /api/queue/{id}/cancel
    // -------------------------------------------------------------------------

    [Fact]
    public async Task Cancel_PendingItem_Returns200()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Pending);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("message").GetString().Should().Be("Queue item cancelled.");
    }

    [Fact]
    public async Task Cancel_AfterCall_StatusIsCancelled()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Pending);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);

        var getResponse = await client.GetAsync($"/api/queue/{item.QueueId}");
        var body = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Cancelled");
    }

    [Fact]
    public async Task Cancel_FailedItem_Returns200()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Failed, attemptCount: 1);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Cancel_SentItem_Returns400()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Sent);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);  // ← was 409
    }

    [Fact]
    public async Task Cancel_AlreadyCancelled_Returns400()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
            status: NotificationQueueStatus.Cancelled);
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);  // ← was 409
    }

    [Fact]
    public async Task Cancel_NotFound_Returns404()
    {
        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.PostAsync("/api/queue/99999/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Cancel_AsUser_Returns403()
    {
        var item = await NotificationSeeder.SeedQueueItemAsync(Factory.Services);
        var client = Factory.CreateClient().WithAuth(1, "User");
        var response = await client.PostAsync($"/api/queue/{item.QueueId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Cancel_Unauthenticated_Returns401()
    {
        var response = await Factory.CreateClient().PostAsync("/api/queue/1/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // -------------------------------------------------------------------------
    // Pagination
    // -------------------------------------------------------------------------

    [Fact]
    public async Task GetAll_Pagination_SecondPageReturnsCorrectSlice()
    {
        for (var i = 0; i < 25; i++)
            await NotificationSeeder.SeedQueueItemAsync(Factory.Services,
                status: NotificationQueueStatus.Pending);

        var client = Factory.CreateClient().WithAuth(1, "Admin");
        var response = await client.GetAsync("/api/queue?page=2&pageSize=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("page").GetInt32().Should().Be(2);
        body.GetProperty("pageSize").GetInt32().Should().Be(10);
        body.GetProperty("totalCount").GetInt32().Should().BeGreaterThanOrEqualTo(25);
        body.GetProperty("totalPages").GetInt32().Should().BeGreaterThanOrEqualTo(3);
        body.GetProperty("items").GetArrayLength().Should().Be(10);
    }

}
