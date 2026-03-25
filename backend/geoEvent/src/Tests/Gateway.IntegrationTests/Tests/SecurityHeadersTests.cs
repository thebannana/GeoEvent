using FluentAssertions;

namespace ApiGateway.IntegrationTests.Tests;

public class SecurityHeadersTests : IClassFixture<GatewayWebApplicationFactory>
{
    private readonly GatewayWebApplicationFactory _factory;

    public SecurityHeadersTests(GatewayWebApplicationFactory factory)
        => _factory = factory;

    [Fact]
    public async Task AllResponses_ContainXContentTypeOptions()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().ContainKey("X-Content-Type-Options");
        response.Headers.GetValues("X-Content-Type-Options").Should().Contain("nosniff");
    }

    [Fact]
    public async Task AllResponses_ContainXFrameOptions()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().ContainKey("X-Frame-Options");
        response.Headers.GetValues("X-Frame-Options").Should().Contain("DENY");
    }

    [Fact]
    public async Task AllResponses_ContainXssProtection()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().ContainKey("X-XSS-Protection");
        response.Headers.GetValues("X-XSS-Protection").Should().Contain("1; mode=block");
    }

    [Fact]
    public async Task AllResponses_ContainReferrerPolicy()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().ContainKey("Referrer-Policy");
        response.Headers.GetValues("Referrer-Policy")
            .Should().Contain("strict-origin-when-cross-origin");
    }

    [Fact]
    public async Task AllResponses_ContainContentSecurityPolicy()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().ContainKey("Content-Security-Policy");
    }

    [Fact]
    public async Task AllResponses_DoNotExposeServerHeader()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        response.Headers.Should().NotContainKey("Server");
    }

    [Fact]
    public async Task SecurityHeaders_AlsoPresentOnProxiedRoutes()
    {
        var client = _factory.CreateAuthenticatedClient();
        var response = await client.GetAsync("/api/notifications");
        response.Headers.Should().ContainKey("X-Content-Type-Options");
        response.Headers.Should().ContainKey("X-Frame-Options");
    }
}
