using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using EventService.IntegrationTests.Helpers;

namespace EventService.IntegrationTests.Tests;

public class BookmarkTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public BookmarkTests(CustomWebApplicationFactory factory) : base(factory) { }

    private static void SetAuth(HttpClient client, int userId, string role = "User")
        => client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer",
                HttpClientExtensions.GenerateJwt(userId, role));

    private async Task<int> CreatePublishedEventAsync(HttpClient client)
    {
        SetAuth(client, 1, "Organizer");
        var ev = await client.PostAsJsonAsync("/api/events", new
        {
            title = $"Event {Guid.NewGuid():N}"[..30],
            description = "A valid description for an integration test event.",
            latitude = 43.8563m,
            longitude = 18.4131m,
            startDateTime = DateTime.UtcNow.AddDays(7).ToString("O"),
            endDateTime = DateTime.UtcNow.AddDays(7).AddHours(3).ToString("O"),
            capacity = 100,
            price = 0m,
            isOnline = false,
            locale = "bs-BA"
        });
        ev.EnsureSuccessStatusCode();
        var body = await ev.Content.ReadFromJsonAsync<JsonElement>();
        var eventId = body.TryGetProperty("eventId", out var id) ? id.GetInt32() : body.GetProperty("EventId").GetInt32();
        await client.PostAsync($"/api/events/{eventId}/publish", null);
        return eventId;
    }

    // ── GET /api/bookmarks ────────────────────────────────────────

    [Fact]
    public async Task GetBookmarks_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/bookmarks");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetBookmarks_WithAuth_Returns200()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);
        var response = await client.GetAsync("/api/bookmarks");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/bookmarks ───────────────────────────────────────

    [Fact]
    public async Task CreateBookmark_WithAuth_Returns201()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        var response = await client.PostAsJsonAsync("/api/bookmarks", new
        {
            eventId,
            memo = "Want to attend"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    [Fact]
    public async Task CreateBookmark_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.PostAsJsonAsync("/api/bookmarks", new { eventId = 1 });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CreateBookmark_Duplicate_Returns400()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        var second = await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── PATCH /api/bookmarks/{id} ─────────────────────────────────

    [Fact]
    public async Task UpdateBookmark_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        var create = await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var bookmarkId = body.TryGetProperty("bookmarkId", out var id) ? id.GetInt32() : body.GetProperty("BookmarkId").GetInt32();

        var response = await client.PatchAsJsonAsync($"/api/bookmarks/{bookmarkId}", new
        {
            memo = "Updated memo"
        });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateBookmark_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        var create = await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var bookmarkId = body.TryGetProperty("bookmarkId", out var id) ? id.GetInt32() : body.GetProperty("BookmarkId").GetInt32();

        SetAuth(client, 3);
        var response = await client.PatchAsJsonAsync($"/api/bookmarks/{bookmarkId}", new
        {
            memo = "Stealing memo"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── DELETE /api/bookmarks/{id} ────────────────────────────────

    [Fact]
    public async Task DeleteBookmark_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        var create = await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var bookmarkId = body.TryGetProperty("bookmarkId", out var id) ? id.GetInt32() : body.GetProperty("BookmarkId").GetInt32();

        var response = await client.DeleteAsync($"/api/bookmarks/{bookmarkId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task DeleteBookmark_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);

        SetAuth(client, 2);
        var create = await client.PostAsJsonAsync("/api/bookmarks", new { eventId });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var bookmarkId = body.TryGetProperty("bookmarkId", out var id) ? id.GetInt32() : body.GetProperty("BookmarkId").GetInt32();

        SetAuth(client, 3);
        var response = await client.DeleteAsync($"/api/bookmarks/{bookmarkId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}
