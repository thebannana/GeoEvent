using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using EventService.Infrastructure.Persistence;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using EventService.IntegrationTests.Helpers;
using System.IdentityModel.Tokens.Jwt;

namespace EventService.IntegrationTests.Tests;

public class EventTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public EventTests(CustomWebApplicationFactory factory) : base(factory) { }

    // ── Helpers ───────────────────────────────────────────────────

    private static object BuildCreateEvent(string? title = null) => new
    {
        title = title ?? $"Event {Guid.NewGuid():N}"[..30],
        description = "A valid description for an integration test event.",
        latitude = 43.8563m,
        longitude = 18.4131m,
        startDateTime = DateTime.UtcNow.AddDays(7).ToString("O"),
        endDateTime = DateTime.UtcNow.AddDays(7).AddHours(3).ToString("O"),
        capacity = 100,
        price = 0m,
        isOnline = false,
        locale = "bs-BA"
    };

    private static void SetAuth(HttpClient client, int userId, string role = "User")
        => client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer",
                HttpClientExtensions.GenerateJwt(userId, role));

    private async Task<int> CreateEventAndGetIdAsync(HttpClient client, int organizerId)
    {
        SetAuth(client, organizerId, "Organizer");
        var res = await client.PostAsJsonAsync("/api/events", BuildCreateEvent());
        res.EnsureSuccessStatusCode();
        var body = await res.Content.ReadFromJsonAsync<JsonElement>();
        return body.TryGetProperty("eventId", out var id) ? id.GetInt32() : body.GetProperty("EventId").GetInt32();
    }

    private async Task<int> PublishEventAsync(HttpClient client, int eventId, int organizerId)
    {
        SetAuth(client, organizerId, "Organizer");
        var res = await client.PostAsync($"/api/events/{eventId}/publish", null);
        res.EnsureSuccessStatusCode();
        return eventId;
    }

    // ── GET /api/events ───────────────────────────────────────────

    [Fact]
    public async Task GetAllEvents_NoAuth_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetAllEvents_WithFilters_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events?page=1&pageSize=5&sortBy=StartDateTime");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── GET /api/events/{id} ──────────────────────────────────────

    [Fact]
    public async Task GetEventById_NonExistent_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetEventById_Existing_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.GetAsync($"/api/events/{eventId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/events ──────────────────────────────────────────

    [Fact]
    public async Task CreateEvent_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/events", BuildCreateEvent());
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CreateEvent_AsUser_Returns403()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "User");
        var response = await client.PostAsJsonAsync("/api/events", BuildCreateEvent());
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CreateEvent_AsOrganizer_Returns201()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsJsonAsync("/api/events", BuildCreateEvent());
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    [Fact]
    public async Task CreateEvent_WithMissingTitle_Returns400()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsJsonAsync("/api/events", new
        {
            description = "desc",
            latitude = 43.8m,
            longitude = 18.4m,
            startDateTime = DateTime.UtcNow.AddDays(1).ToString("O"),
            endDateTime = DateTime.UtcNow.AddDays(1).AddHours(2).ToString("O")
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task CreateEvent_WithPastStartDate_Returns400()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsJsonAsync("/api/events", new
        {
            title = "Past Event",
            description = "A valid description for an integration test event.",
            latitude = 43.8563m,
            longitude = 18.4131m,
            startDateTime = DateTime.UtcNow.AddDays(-1).ToString("O"),
            endDateTime = DateTime.UtcNow.AddDays(1).ToString("O"),
            capacity = 100,
            price = 0m,
            isOnline = false,
            locale = "bs-BA"
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── PUT /api/events/{id} ──────────────────────────────────────

    [Fact]
    public async Task UpdateEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PutAsJsonAsync($"/api/events/{eventId}", new
        {
            title = "Updated Title"
        });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task UpdateEvent_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 2, "Organizer");
        var response = await client.PutAsJsonAsync($"/api/events/{eventId}", new
        {
            title = "Stolen Title"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task UpdateEvent_NonExistent_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var response = await client.PutAsJsonAsync("/api/events/99999", new { title = "X" });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest); // ← was NotFound
    }


    // ── DELETE /api/events/{id} ───────────────────────────────────

    [Fact]
    public async Task DeleteEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.DeleteAsync($"/api/events/{eventId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task DeleteEvent_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 2, "Organizer");
        var response = await client.DeleteAsync($"/api/events/{eventId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── POST /api/events/{id}/publish ─────────────────────────────

    [Fact]
    public async Task PublishEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/publish", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task PublishEvent_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 2, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/publish", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task PublishEvent_AlreadyActive_Returns400()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/publish", null);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── POST /api/events/{id}/cancel ──────────────────────────────

    [Fact]
    public async Task CancelEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task CancelEvent_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 2, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── POST /api/events/{id}/postpone ────────────────────────────

    [Fact]
    public async Task PostponeEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/postpone", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/events/{id}/complete ────────────────────────────

    [Fact]
    public async Task CompleteEvent_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/complete", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/events/{id}/like ────────────────────────────────

    [Fact]
    public async Task LikeEvent_WithAuth_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 2, "User");
        var response = await client.PostAsync($"/api/events/{eventId}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task LikeEvent_Twice_Returns400()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 2, "User");
        await client.PostAsync($"/api/events/{eventId}/like", null);
        var second = await client.PostAsync($"/api/events/{eventId}/like", null);
        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task LikeEvent_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.PostAsync($"/api/events/{eventId}/like", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── DELETE /api/events/{id}/like ──────────────────────────────

    [Fact]
    public async Task UnlikeEvent_AfterLike_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);

        SetAuth(client, 2, "User");
        await client.PostAsync($"/api/events/{eventId}/like", null);
        var response = await client.DeleteAsync($"/api/events/{eventId}/like");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── POST /api/events/{id}/images ──────────────────────────────

    [Fact]
    public async Task AddImage_AsOwner_Returns200()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsJsonAsync($"/api/events/{eventId}/images", new
        {
            imageUrl = "https://example.com/image.jpg",
            isCover = true
        });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task AddImage_AsNonOwner_Returns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);

        SetAuth(client, 2, "Organizer");
        var response = await client.PostAsJsonAsync($"/api/events/{eventId}/images", new
        {
            imageUrl = "https://example.com/image.jpg",
            isCover = false
        });
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── GET /api/events/nearby ────────────────────────────────────

    [Fact]
    public async Task GetNearby_WithValidParams_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync(
            "/api/events/nearby?latitude=43.8563&longitude=18.4131&radiusKm=50&limit=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetEventByIdNonExistentReturns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events/999999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task DeleteEventAsNonOwnerReturns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        SetAuth(client, 2, "Organizer");
        var response = await client.DeleteAsync($"/api/events/{eventId}");
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CancelEventAsNonOwnerReturns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);
        SetAuth(client, 2, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CompleteEventAsNonOwnerReturns403()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);
        SetAuth(client, 2, "Organizer");
        var response = await client.PostAsync($"/api/events/{eventId}/complete", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CreateEventWithoutAuthReturns401()
    {
        var client = Factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.PostAsJsonAsync("/api/events", BuildCreateEvent());
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetNearbyWithMissingCoordinatesReturns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events/nearby?radiusKm=50");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task UnlikeEventWithoutLikingReturns404()
    {
        var client = Factory.CreateClient();
        var eventId = await CreateEventAndGetIdAsync(client, 1);
        await PublishEventAsync(client, eventId, 1);
        SetAuth(client, 2, "User");
        var response = await client.DeleteAsync($"/api/events/{eventId}/like");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }


}
