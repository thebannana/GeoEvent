using System.Net;
using System.Net.Http.Headers;
using FluentAssertions;

namespace ApiGateway.IntegrationTests.Tests;

public class AuthenticationTests : IClassFixture<GatewayWebApplicationFactory>
{
    private readonly GatewayWebApplicationFactory _factory;

    public AuthenticationTests(GatewayWebApplicationFactory factory)
        => _factory = factory;

    [Fact]
    public async Task ValidJwt_ProtectedRoute_Returns200()
    {
        var client = _factory.CreateAuthenticatedClient();
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task NoToken_ProtectedRoute_Returns401()
    {
        var response = await _factory.CreateClient().GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task MalformedToken_ProtectedRoute_Returns401()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "this.is.not.a.valid.jwt");
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ExpiredToken_ProtectedRoute_Returns401()
    {
        // Generate a token already expired
        var expiredToken = GatewayWebApplicationFactory.GenerateJwt(1);
        // Manually craft expired — use a known-expired token string
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer",
                "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9." +
                "eyJzdWIiOiIxIiwianRpIjoiYWJjIiwibmJmIjoxNjAwMDAwMDAwLCJleHAiOjE2MDAwMDAwMDEsImlhdCI6MTYwMDAwMDAwMCwiaXNzIjoiR2VvRXZlbnQiLCJhdWQiOiJHZW9FdmVudFVzZXJzIn0." +
                "INVALIDSIGNATURE");
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task WrongIssuer_ProtectedRoute_Returns401()
    {
        // Token signed with correct key but wrong issuer
        var token = GatewayWebApplicationFactory.GenerateJwtWithCustomIssuer(
            "wrong-issuer", "GeoEventUsers");
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task WrongAudience_ProtectedRoute_Returns401()
    {
        var token = GatewayWebApplicationFactory.GenerateJwtWithCustomIssuer(
            "GeoEvent", "wrong-audience");
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
        var response = await client.GetAsync("/api/notifications");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ValidToken_PublicRoute_Returns200()
    {
        // Token shouldn't break public routes either
        var client = _factory.CreateAuthenticatedClient();
        var response = await client.GetAsync("/api/auth/login");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
