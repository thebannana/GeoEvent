using System.Text;
using AspNetCoreRateLimit;
using ApiGateway.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.IdentityModel.Tokens;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    if (!builder.Environment.IsEnvironment("Testing"))
    {
        builder.Host.UseSerilog((ctx, cfg) =>
            cfg.ReadFrom.Configuration(ctx.Configuration)
               .WriteTo.Console());
    }

    builder.Services.Configure<ForwardedHeadersOptions>(options =>
    {
        options.ForwardedHeaders =
            ForwardedHeaders.XForwardedFor |
            ForwardedHeaders.XForwardedProto |
            ForwardedHeaders.XForwardedHost;

        options.KnownNetworks.Clear();
        options.KnownProxies.Clear();
    });

    builder.Services
        .AddReverseProxy()
        .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

    var jwtSettings = builder.Configuration.GetSection("Jwt");
    var issuer = jwtSettings["Issuer"];
    var audience = jwtSettings["Audience"];
    var secretKey = jwtSettings["SecretKey"];

    if (string.IsNullOrWhiteSpace(secretKey))
        throw new InvalidOperationException("JWT SecretKey is missing.");
    if (string.IsNullOrWhiteSpace(issuer))
        throw new InvalidOperationException("JWT Issuer is missing.");
    if (string.IsNullOrWhiteSpace(audience))
        throw new InvalidOperationException("JWT Audience is missing.");

    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false;
            options.SaveToken = false;

            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = issuer,
                ValidAudience = audience,
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(secretKey)),
                ClockSkew = TimeSpan.Zero,
                RoleClaimType = "role"
            };

            options.Events = new JwtBearerEvents
            {
                OnMessageReceived = context =>
                {
                    var accessToken = context.Request.Query["access_token"];
                    var path = context.HttpContext.Request.Path;

                    if (!string.IsNullOrEmpty(accessToken) &&
                        path.StartsWithSegments("/hubs/chat"))
                    {
                        context.Token = accessToken;
                    }

                    return Task.CompletedTask;
                }
            };
        });

    builder.Services.AddAuthorization(options =>
    {
        options.AddPolicy("authenticated", policy =>
            policy.RequireAuthenticatedUser());

        options.AddPolicy("admin", policy =>
            policy.RequireAuthenticatedUser()
                  .RequireRole("Admin"));
    });

    builder.Services.AddMemoryCache();
    builder.Services.Configure<IpRateLimitOptions>(
        builder.Configuration.GetSection("IpRateLimiting"));
    builder.Services.Configure<IpRateLimitPolicies>(
        builder.Configuration.GetSection("IpRateLimitPolicies"));
    builder.Services.AddInMemoryRateLimiting();
    builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

    var corsOrigins = builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>();

    if (corsOrigins == null || corsOrigins.Length == 0)
        throw new InvalidOperationException("Cors:AllowedOrigins is not configured.");

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("GeoEventCors", policy =>
        {
            policy.WithOrigins(corsOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
    });

    builder.Services.AddOpenApi();

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
    }

    app.UseForwardedHeaders();
    app.UseMiddleware<SecurityHeadersMiddleware>();

    if (!app.Environment.IsDevelopment())
    {
        app.UseHsts();
    }

    app.UseRouting();
    app.UseCors("GeoEventCors");
    app.UseIpRateLimiting();
    app.UseAuthentication();
    app.UseAuthorization();

    app.MapGet("/health", () =>
        Results.Ok(new
        {
            status = "healthy",
            service = "api-gateway",
            timestamp = DateTime.UtcNow
        }))
        .AllowAnonymous();

    app.MapGet("/", () =>
        Results.Ok(new
        {
            service = "GeoEvent API Gateway",
            environment = app.Environment.EnvironmentName,
            timestamp = DateTime.UtcNow
        }))
        .AllowAnonymous();

    app.MapReverseProxy();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "API Gateway terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

public partial class Program { }