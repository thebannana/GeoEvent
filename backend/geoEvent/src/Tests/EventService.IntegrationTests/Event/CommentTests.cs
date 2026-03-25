using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using EventService.IntegrationTests.Helpers;
using System.IdentityModel.Tokens.Jwt;

namespace EventService.IntegrationTests.Tests;

public class CommentTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public CommentTests(CustomWebApplicationFactory factory) : base(factory) { }

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

    private async Task<int> CreateCommentAsync(HttpClient client, int eventId, int userId)
    {
        SetAuth(client, userId);
        var res = await client.PostAsJsonAsync("/api/comments", new
        {
            eventId,
            content = "This is a test comment."
        });
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadFromJsonAsync<JsonElement>();
        return body.TryGetProperty("commentId", out var id) ? id.GetInt32() : body.GetProperty("CommentId").GetInt32();
    }

    // ── GET /api/comments/event/{id} ──────────────────────────────

    [Fact]
    public async Task GetComments_NoAuth_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.GetAsync($"/api/comments/event/{eventId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/comments ────────────────────────────────────────

    [Fact]
    public async Task CreateComment_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/comments", new
        {
            eventId = 1,
            content = "Test comment"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CreateComment_WithAuth_Returns201()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        SetAuth(client, 2);
        var response = await client.PostAsJsonAsync("/api/comments", new
        {
            eventId,
            content = "This is a valid comment."
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    [Fact]
    public async Task CreateReply_ToExistingComment_Returns201()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        var response = await client.PostAsJsonAsync("/api/comments", new
        {
            eventId,
            content = "This is a reply.",
            parentCommentId = commentId
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    // ── PUT /api/comments/{id} ────────────────────────────────────

    [Fact]
    public async Task UpdateComment_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 2);
        var response = await client.PutAsJsonAsync($"/api/comments/{commentId}", new
        {
            content = "Updated comment content."
        });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateComment_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        var response = await client.PutAsJsonAsync($"/api/comments/{commentId}", new
        {
            content = "Hijacked content."
        });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── DELETE /api/comments/{id} ─────────────────────────────────

    [Fact]
    public async Task DeleteComment_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 2);
        var response = await client.DeleteAsync($"/api/comments/{commentId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task DeleteComment_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        var response = await client.DeleteAsync($"/api/comments/{commentId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── POST /api/comments/{id}/like ──────────────────────────────

    [Fact]
    public async Task LikeComment_WithAuth_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        var response = await client.PostAsync($"/api/comments/{commentId}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task LikeComment_Twice_Returns409()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        await client.PostAsync($"/api/comments/{commentId}/like", null);
        var second = await client.PostAsync($"/api/comments/{commentId}/like", null);
        second.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    // ── DELETE /api/comments/{id}/like ────────────────────────────

    [Fact]
    public async Task UnlikeComment_AfterLike_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        SetAuth(client, 3);
        await client.PostAsync($"/api/comments/{commentId}/like", null);
        var response = await client.DeleteAsync($"/api/comments/{commentId}/like");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── GET /api/comments/{id}/replies ────────────────────────────

    [Fact]
    public async Task GetReplies_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);

        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.GetAsync($"/api/comments/{commentId}/replies");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateCommentAsNonOwnerReturns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);
        SetAuth(client, 3); // different user
        var response = await client.PutAsJsonAsync($"/api/comments/{commentId}",
            new { content = "Hijacked content." });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task DeleteCommentAsNonOwnerReturns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        var commentId = await CreateCommentAsync(client, eventId, 2);
        SetAuth(client, 3); // different user
        var response = await client.DeleteAsync($"/api/comments/{commentId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task ReplyToNonExistentCommentReturns404()
    {
        var client = Factory.CreateClient();
        var eventId = await CreatePublishedEventAsync(client);
        SetAuth(client, 2);
        var response = await client.PostAsJsonAsync("/api/comments", new
        {
            eventId,
            content = "This is a reply",
            parentCommentId = 999999
        });
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }



}
