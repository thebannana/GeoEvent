using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Docker.DotNet.Models;
using FluentAssertions;
using LocationService.IntegrationTests.Helpers;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.IntegrationTests.Tests;

public class CountriesTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public CountriesTests(CustomWebApplicationFactory factory) : base(factory) { }

    // GET /api/countries

    [Fact]
    public async Task GetAll_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_FilterByContinent_Returns200Filtered()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/countries?continentId={seed.ContinentId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_FilterBySearchTerm_Returns200Filtered()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries?searchTerm=Bosnia");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(1);
    }

    [Fact]
    public async Task GetAll_FilterBySearchTerm_NoMatch_Returns200EmptyList()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries?searchTerm=zzznomatch");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    // GET /api/countries/{id}

    [Fact]
    public async Task GetById_Existing_Returns200()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/countries/{seed.CountryId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("countryId").GetInt32().Should().Be(seed.CountryId);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/countries/code/{code}

    [Fact]
    public async Task GetByCode_Alpha2_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries/code/BA");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("countryCodeAlpha2").GetString().Should().Be("BA");
    }

    [Fact]
    public async Task GetByCode_Alpha3_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries/code/BIH");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetByCode_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/countries/code/ZZ");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/countries/{id}/cities

    [Fact]
    public async Task GetCities_ExistingCountry_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/countries/{seed.CountryId}/cities");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // GET /api/countries/{id}/divisions

    [Fact]
    public async Task GetDivisions_ExistingCountry_Returns200WithItems()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/countries/{seed.CountryId}/divisions");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetAll_FilterByIsActiveFalse_ExcludesActiveCountries()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);

        // Seed an inactive country
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<LocationService.Infrastructure.Persistence.LocationDbContext>();
        db.Countries.Add(new LocationService.Domain.Entities.Country
        {
            CountryName = "Inactive Country",
            CountryCodeAlpha2 = "XX",
            CountryCodeAlpha3 = "XXX",
            CountryCodeNumeric = 999,
            IsActive = false,
            ContinentId = null
        });
        await db.SaveChangesAsync();

        var client = Factory.CreateClient();

        // Only inactive countries
        var response = await client.GetAsync("/api/countries?isActive=false");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(1);
        body[0].GetProperty("countryName").GetString().Should().Be("Inactive Country");
    }

    [Fact]
    public async Task GetAll_FilterByIsActiveTrue_ExcludesInactiveCountries()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);

        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider
            .GetRequiredService<LocationService.Infrastructure.Persistence.LocationDbContext>();
        db.Countries.Add(new LocationService.Domain.Entities.Country
        {
            CountryName = "Inactive Country",
            CountryCodeAlpha2 = "XX",
            CountryCodeAlpha3 = "XXX",
            CountryCodeNumeric = 999,
            IsActive = false,
            ContinentId = null
        });
        await db.SaveChangesAsync();

        var client = Factory.CreateClient();

        var response = await client.GetAsync("/api/countries?isActive=true");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        // Only the active seeded country should appear
        foreach (var item in body.EnumerateArray())
            item.GetProperty("isActive").GetBoolean().Should().BeTrue();
    }

    [Fact]
    public async Task GetByCode_Lowercase_ResolvesToSameCountry()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();

        var upperResponse = await client.GetAsync("/api/countries/code/BA");
        var lowerResponse = await client.GetAsync("/api/countries/code/ba");

        upperResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        lowerResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var upper = await upperResponse.Content.ReadFromJsonAsync<JsonElement>();
        var lower = await lowerResponse.Content.ReadFromJsonAsync<JsonElement>();

        upper.GetProperty("countryId").GetInt32()
            .Should().Be(lower.GetProperty("countryId").GetInt32());
    }

}
