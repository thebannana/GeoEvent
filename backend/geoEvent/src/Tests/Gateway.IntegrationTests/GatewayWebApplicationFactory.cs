using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;
using WireMock.Server;
using Microsoft.Extensions.Logging;
using Serilog;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.DependencyInjection;

namespace ApiGateway.IntegrationTests;



public class GatewayWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    // At the top of your factory class, before CreateClient() is ever called
    static GatewayWebApplicationFactory()
    {
        // Reset Serilog so it can be re-frozen by each test host
        Log.CloseAndFlush();
        Log.Logger = Serilog.Core.Logger.None;
    }

    // One WireMock stub server per downstream cluster
    public WireMockServer UserService { get; private set; } = null!;
    public WireMockServer EventService { get; private set; } = null!;
    public WireMockServer TicketService { get; private set; } = null!;
    public WireMockServer NotificationService { get; private set; } = null!;
    public WireMockServer MessageService { get; private set; } = null!;
    public WireMockServer LocationService { get; private set; } = null!;

    private const string JwtSecret =
        "geoEventSuperSecretJWTKey2026ThisMustBeAtLeast64CharactersLongForSHA512!!";

    public Task InitializeAsync()
    {
        UserService = WireMockServer.Start();
        EventService = WireMockServer.Start();
        TicketService = WireMockServer.Start();
        NotificationService = WireMockServer.Start();
        MessageService = WireMockServer.Start();
        LocationService = WireMockServer.Start();

        StubAll(UserService);
        StubAll(EventService);
        StubAll(TicketService);
        StubAll(NotificationService);
        StubAll(MessageService);
        StubAll(LocationService);

        return Task.CompletedTask;
    }

    public new Task DisposeAsync()
    {
        UserService.Stop();
        EventService.Stop();
        TicketService.Stop();
        NotificationService.Stop();
        MessageService.Stop();
        LocationService.Stop();
        return Task.CompletedTask;
    }

    // Stub every path on a server to return 200
    private static void StubAll(WireMockServer server)
    {
        server
            .Given(Request.Create().WithPath("/*").UsingAnyMethod())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithBody("{\"stub\":true}")
                .WithHeader("Content-Type", "application/json"));
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureLogging(logging =>
        {
            logging.ClearProviders(); // removes Serilog and all other providers
        });

        builder.UseSetting("ASPNETCORE_ENVIRONMENT", "Testing");

        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            services.PostConfigure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
            {
                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JwtSecret))
                {
                    KeyId = "geoevent-key"  // ← must match token
                };
                options.TokenValidationParameters.IssuerSigningKey = key;
            });
        });

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Issuer"] = "GeoEvent",
                ["Jwt:Audience"] = "GeoEventUsers",
                ["Jwt:SecretKey"] = JwtSecret,

                // Point every cluster to its WireMock stub
                ["ReverseProxy:Clusters:user-cluster:Destinations:user-service:Address"]
                    = UserService.Urls[0],
                ["ReverseProxy:Clusters:event-cluster:Destinations:event-service:Address"]
                    = EventService.Urls[0],
                ["ReverseProxy:Clusters:ticket-cluster:Destinations:ticket-service:Address"]
                    = TicketService.Urls[0],
                ["ReverseProxy:Clusters:notification-cluster:Destinations:notification-service:Address"]
                    = NotificationService.Urls[0],
                ["ReverseProxy:Clusters:message-cluster:Destinations:message-service:Address"]
                    = MessageService.Urls[0],
                ["ReverseProxy:Clusters:location-cluster:Destinations:location-service:Address"]
                    = LocationService.Urls[0],

                // Generous rate limits for most tests — RateLimitingTests override per-test
                ["IpRateLimiting:GeneralRules:0:Endpoint"] = "*",
                ["IpRateLimiting:GeneralRules:0:Period"] = "1m",
                ["IpRateLimiting:GeneralRules:0:Limit"] = "1000",
            });
        });
    }

    public static string GenerateJwt(int userId = 1, string role = "User")
    {
        var claims = new[]
        {
        new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
        new Claim(ClaimTypes.Role, role),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JwtSecret))
        {
            KeyId = "geoevent-key"  // ← ADD THIS
        };
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: "GeoEvent",
            audience: "GeoEventUsers",
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }


    public HttpClient CreateAuthenticatedClient(int userId = 1, string role = "User")
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", GenerateJwt(userId, role));
        return client;
    }

    public static string GenerateJwtWithCustomIssuer(string issuer, string audience)
    {
        var claims = new[] { new Claim(ClaimTypes.NameIdentifier, "1") };
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JwtSecret))
        {
            KeyId = "geoevent-key"  // ← ADD THIS
        };
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

}
