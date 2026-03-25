using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Docker.DotNet.Models;
using FluentAssertions;
using LocationService.IntegrationTests.Helpers;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.IntegrationTests.Tests;

public class ContinentsTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public ContinentsTests(CustomWebApplicationFactory factory) : base(factory) { }

    // GET /api/continents

    [Fact]
    public async Task GetAll_NoData_Returns200EmptyList()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/continents");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task GetAll_WithData_Returns200WithItems()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/continents");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_IsAnonymous_Returns200()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/continents");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // GET /api/continents/{id}

    [Fact]
    public async Task GetById_Existing_Returns200WithCorrectId()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/continents/{seed.ContinentId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("continentId").GetInt32().Should().Be(seed.ContinentId);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/continents/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/continents/{id}/countries

    [Fact]
    public async Task GetCountries_ExistingContinent_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/continents/{seed.ContinentId}/countries");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetCountries_NoCountriesForContinent_Returns200EmptyList()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        // Seed a second continent with no countries
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<LocationService.Infrastructure.Persistence.LocationDbContext>();
        var emptyContinent = new LocationService.Domain.Entities.Continent
        {
            ContinentName = "Antarctica",
            ContinentCode = "AN"
        };
        db.Continents.Add(emptyContinent);
        await db.SaveChangesAsync();

        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/continents/{emptyContinent.ContinentId}/countries");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }
}
