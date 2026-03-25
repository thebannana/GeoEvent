using System.Net;
using FluentAssertions;

namespace ApiGateway.IntegrationTests.Tests;

public class RoutingTests : IClassFixture<GatewayWebApplicationFactory>
{
    private readonly GatewayWebApplicationFactory _factory;

    public RoutingTests(GatewayWebApplicationFactory factory)
        => _factory = factory;

    // -------------------------------------------------------------------------
    // Health check
    // -------------------------------------------------------------------------

    [Fact]
    public async Task HealthCheck_ReturnsOk()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // -------------------------------------------------------------------------
    // Public routes — no auth required
    // -------------------------------------------------------------------------

    [Theory]
    [InlineData("/api/auth/login")]
    [InlineData("/api/auth/register")]
    [InlineData("/api/public/events")]
    [InlineData("/api/public/venues")]
    [InlineData("/api/locations")]
    [InlineData("/api/cities")]
    [InlineData("/api/continents")]
    [InlineData("/api/countries")]
    [InlineData("/api/regions")]
    public async Task PublicRoutes_NoToken_Returns200(string path)
    {
        var response = await _factory.CreateClient().GetAsync(path);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // -------------------------------------------------------------------------
    // Protected routes — auth required
    // -------------------------------------------------------------------------

    [Theory]
    [InlineData("/api/users/me")]
    [InlineData("/api/events")]
    [InlineData("/api/tickets")]
    [InlineData("/api/reservations")]
    [InlineData("/api/notifications")]
    [InlineData("/api/messages")]
    public async Task ProtectedRoutes_NoToken_Returns401(string path)
    {
        var response = await _factory.CreateClient().GetAsync(path);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Theory]
    [InlineData("/api/users/me")]
    [InlineData("/api/events")]
    [InlineData("/api/tickets")]
    [InlineData("/api/reservations")]
    [InlineData("/api/notifications")]
    [InlineData("/api/messages")]
    public async Task ProtectedRoutes_ValidToken_ProxiedToDownstream(string path)
    {
        var client = _factory.CreateAuthenticatedClient();
        var response = await client.GetAsync(path);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // -------------------------------------------------------------------------
    // Unknown routes
    // -------------------------------------------------------------------------

    [Fact]
    public async Task UnknownRoute_Returns404()
    {
        var client = _factory.CreateAuthenticatedClient();
        var response = await client.GetAsync("/api/nonexistent/endpoint");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
