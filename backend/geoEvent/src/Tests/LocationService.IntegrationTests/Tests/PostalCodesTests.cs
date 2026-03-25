using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Docker.DotNet.Models;
using FluentAssertions;
using LocationService.IntegrationTests.Helpers;

namespace LocationService.IntegrationTests.Tests;

public class PostalCodesTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public PostalCodesTests(CustomWebApplicationFactory factory) : base(factory) { }

    // GET /api/postal-codes/{id}

    [Fact]
    public async Task GetById_Existing_Returns200()
    {
        var seed = await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync($"/api/postal-codes/{seed.PostalCodeId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("postalCodeId").GetInt32().Should().Be(seed.PostalCodeId);
    }

    [Fact]
    public async Task GetById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/postal-codes/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // GET /api/postal-codes/code/{code}

    [Fact]
    public async Task GetByCode_Existing_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/postal-codes/code/71000");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("code").GetString().Should().Be("71000");
    }

    [Fact]
    public async Task GetByCode_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/postal-codes/code/00000");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetByCode_IsAnonymous_Returns200()
    {
        await LocationSeeder.SeedFullHierarchyAsync(Factory.Services);
        var client = Factory.CreateClient();
        // No auth header
        var response = await client.GetAsync("/api/postal-codes/code/71000");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
