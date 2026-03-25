using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Docker.DotNet.Models;
using FluentAssertions;
using LocationService.IntegrationTests.Helpers;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.IntegrationTests.Tests;

public class CitiesTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public CitiesTests(CustomWebApplicationFactory factory) : base(factory) { }

    // GET /api/cities

    [Fact]
    public async Task GetAll_WithData_Returns200PagedResult()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().BeGreaterThan(0);
        body.GetProperty("items").GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_NoData_Returns200EmptyPagedResult()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task GetAll_FilterByDivisionId_Returns200Filtered()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/cities?divisionId={seed.DivisionId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetAll_FilterBySearchTerm_Returns200Filtered()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities?searchTerm=sarajevo");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("totalCount").GetInt32().Should().Be(1);
    }

    [Fact]
    public async Task GetAll_Pagination_Returns200CorrectPage()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities?page=1&pageSize=5");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("page").GetInt32().Should().Be(1);
        body.GetProperty("pageSize").GetInt32().Should().Be(5);
    }

    // GET /api/cities/{id}

    [Fact]
    public async Task GetById_Existing_Returns200WithPostalCodes()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/cities/{seed.CityId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("cityId").GetInt32().Should().Be(seed.CityId);
        body.GetProperty("postalCodes").GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/cities/search?term=...

    [Fact]
    public async Task Search_WithResults_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/search?term=sara");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task Search_NoResults_Returns200EmptyList()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/search?term=zzznomatch");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task Search_EmptyTerm_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/search?term=");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Search_WithLimitParam_RespectsLimit()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/search?term=sara&limit=1");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeLessThanOrEqualTo(1);
    }

    // GET /api/cities/nearby

    [Fact]
    public async Task GetNearby_WithCitiesInRange_Returns200WithItems()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        // Sarajevo coords — 10km radius should include the seeded city
        var response = await client.GetAsync("/api/cities/nearby?latitude=43.8563&longitude=18.4131&radiusKm=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetNearby_NoCitiesInRange_Returns200EmptyList()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        // Middle of the Atlantic — no cities
        var response = await client.GetAsync("/api/cities/nearby?latitude=0&longitude=-30&radiusKm=1");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    // GET /api/cities/{id}/postal-codes

    [Fact]
    public async Task GetPostalCodes_ExistingCity_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/cities/{seed.CityId}/postal-codes");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetPostalCodes_CityWithNoCodes_Returns200EmptyList()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);

        // Add a city with no postal codes
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<LocationService.Infrastructure.Persistence.LocationDbContext>();
        var emptyCity = new LocationService.Domain.Entities.City
        {
            CityName = "Mostar",
            NormalizedName = "mostar",
            Latitude = 43.3438m,
            Longitude = 17.8078m,
            IsActive = true,
            DivisionId = seed.DivisionId
        };
        db.Cities.Add(emptyCity);
        await db.SaveChangesAsync();

        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/cities/{emptyCity.CityId}/postal-codes");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task GetNearby_InvalidRadius_TooLarge_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/nearby?latitude=43.8&longitude=18.4&radiusKm=501");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetNearby_InvalidRadius_Zero_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/nearby?latitude=43.8&longitude=18.4&radiusKm=0");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetNearby_InvalidLimit_Zero_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/nearby?latitude=43.8&longitude=18.4&radiusKm=50&limit=0");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetNearby_InvalidLimit_TooLarge_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/cities/nearby?latitude=43.8&longitude=18.4&radiusKm=50&limit=51");
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Search_LimitZero_IsClamped_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        // Controller clamps limit=0 to 1, so it still returns results
        var response = await client.GetAsync("/api/cities/search?term=sara&limit=0");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeLessThanOrEqualTo(1);
    }


}
