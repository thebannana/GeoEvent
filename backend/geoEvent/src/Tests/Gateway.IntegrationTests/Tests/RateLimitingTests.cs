using System.Net;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace ApiGateway.IntegrationTests.Tests;

/// <summary>
/// Uses a separate factory with a very low rate limit to test 429 behavior
/// without hammering the shared factory.
/// </summary>
public class RateLimitingWebApplicationFactory : GatewayWebApplicationFactory
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        base.ConfigureWebHost(builder);

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["IpRateLimiting:GeneralRules:0:Endpoint"] = "*",
                ["IpRateLimiting:GeneralRules:0:Period"] = "1m",
                ["IpRateLimiting:GeneralRules:0:Limit"] = "3",
            });
        });
    }
}

public class RateLimitingTests : IClassFixture<RateLimitingWebApplicationFactory>
{
    private readonly RateLimitingWebApplicationFactory _factory;

    public RateLimitingTests(RateLimitingWebApplicationFactory factory)
        => _factory = factory;

    [Fact]
    public async Task ExceedingRateLimit_Returns429()
    {
        var client = _factory.CreateClient();

        // Burn through the 3-request limit
        for (var i = 0; i < 3; i++)
            await client.GetAsync("/health");

        // 4th request should be rate-limited
        var response = await client.GetAsync("/health");
        response.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
    }

    [Fact]
    public async Task WithinRateLimit_Returns200()
    {
        var client = _factory.CreateClient();

        // Only 2 requests — well within limit
        for (var i = 0; i < 2; i++)
        {
            var response = await client.GetAsync("/health");
            response.StatusCode.Should().Be(HttpStatusCode.OK);
        }
    }
}
