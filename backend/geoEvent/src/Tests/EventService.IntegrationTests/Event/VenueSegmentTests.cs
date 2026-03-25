using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using EventService.IntegrationTests.Helpers;

namespace EventService.IntegrationTests.Tests;

public class VenueSegmentTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public VenueSegmentTests(CustomWebApplicationFactory factory) : base(factory) { }

    private static void SetAuth(HttpClient client, int userId, string role = "Organizer")
        => client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer",
                HttpClientExtensions.GenerateJwt(userId, role));

    // ── Segments ──────────────────────────────────────────────────

    [Fact]
    public async Task GetAllSegments_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/segments");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetSegmentById_NonExistent_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/segments/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetGenresBySegment_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/segments/1/genres");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── Genres ────────────────────────────────────────────────────

    [Fact]
    public async Task GetGenreById_NonExistent_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/genres/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetSubGenresByGenre_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/genres/1/subgenres");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── Venues ────────────────────────────────────────────────────

    [Fact]
    public async Task CreateVenue_AsOrganizer_Returns201()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var response = await client.PostAsJsonAsync("/api/venues", new
        {
            name = "Test Venue",
            latitude = 43.8563m,
            longitude = 18.4131m,
            cityId = 1
        });
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }

    [Fact]
    public async Task CreateVenue_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/venues", new
        {
            name = "Test Venue",
            latitude = 43.8563m,
            longitude = 18.4131m
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetVenueById_NonExistent_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/venues/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetVenueById_Existing_Returns200()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var create = await client.PostAsJsonAsync("/api/venues", new
        {
            name = "My Venue",
            latitude = 43.8563m,
            longitude = 18.4131m,
            cityId = 1
        });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var venueId = body.TryGetProperty("venueId", out var id) ? id.GetInt32() : body.GetProperty("VenueId").GetInt32();

        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.GetAsync($"/api/venues/{venueId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetVenuesByCity_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/venues/city/1");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetPriceZones_Returns200()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var create = await client.PostAsJsonAsync("/api/venues", new
        {
            name = "Venue With Zones",
            latitude = 43.8563m,
            longitude = 18.4131m,
            cityId = 1
        });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var venueId = body.TryGetProperty("venueId", out var id) ? id.GetInt32() : body.GetProperty("VenueId").GetInt32();

        client.DefaultRequestHeaders.Authorization = null;
        var response = await client.GetAsync($"/api/venues/{venueId}/price-zones");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task CreatePriceZone_AsOrganizer_Returns200()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "Organizer");
        var create = await client.PostAsJsonAsync("/api/venues", new
        {
            name = "Venue For PriceZone",
            latitude = 43.8563m,
            longitude = 18.4131m,
            cityId = 1
        });
        var body = await create.Content.ReadFromJsonAsync<JsonElement>();
        var venueId = body.TryGetProperty("venueId", out var id) ? id.GetInt32() : body.GetProperty("VenueId").GetInt32();

        var response = await client.PostAsJsonAsync($"/api/venues/{venueId}/price-zones", new
        {
            venueId,
            name = "VIP Zone",
            description = "Front row seats"
        });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
