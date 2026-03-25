using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Docker.DotNet.Models;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using LocationService.IntegrationTests.Helpers;

namespace LocationService.IntegrationTests.Tests;

public class DivisionsTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public DivisionsTests(CustomWebApplicationFactory factory) : base(factory) { }

    // GET /api/divisions

    [Fact]
    public async Task GetAll_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/divisions");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_FilterByCountry_Returns200Filtered()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/divisions?countryId={seed.CountryId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_FilterByLevel_Returns200Filtered()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/divisions?level=1");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_NoData_Returns200EmptyList()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/divisions");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    // GET /api/divisions/{id}

    [Fact]
    public async Task GetById_Existing_Returns200()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/divisions/{seed.DivisionId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("divisionId").GetInt32().Should().Be(seed.DivisionId);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/divisions/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/divisions/{id}/children

    [Fact]
    public async Task GetChildren_DivisionWithNoChildren_Returns200EmptyList()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/divisions/{seed.DivisionId}/children");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task GetChildren_DivisionWithChildren_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);

        // Add a child division
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<LocationService.Infrastructure.Persistence.LocationDbContext>();
        db.AdministrativeDivisions.Add(new LocationService.Domain.Entities.AdministrativeDivision
        {
            DivisionName = "Kanton Sarajevo",
            DivisionCode = "KS",
            DivisionType = "Canton",
            Level = 2,
            Latitude = 43.8m,
            Longitude = 18.4m,
            IsActive = true,
            CountryId = seed.CountryId,
            ParentDivisionId = seed.DivisionId
        });
        await db.SaveChangesAsync();

        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/divisions/{seed.DivisionId}/children");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(1);
    }

    // GET /api/divisions/{id}/cities

    [Fact]
    public async Task GetCities_ExistingDivision_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/divisions/{seed.DivisionId}/cities");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }
}
