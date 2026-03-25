using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UserService.Infrastructure.Persistence;

namespace UserService.IntegrationTests.Helpers;

public static class HttpClientExtensions
{
    public static Task<HttpResponseMessage> PostJsonAsync(
        this HttpClient client, string url, object body)
        => client.PostAsJsonAsync(url, body);

    public static async Task<string> GetJwtTokenAsync(
    this HttpClient client, string email, string password,
    CustomWebApplicationFactory factory)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email.ToLower());
        if (user != null)
        {
            user.IsVerified = true;
            user.EmailVerifiedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
        }

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,   // ← fix field name
            password
        });
        response.EnsureSuccessStatusCode();

        // Use JsonElement to avoid case-sensitivity issues with Dictionary<string,object>
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var token = body.TryGetProperty("accessToken", out var lower)
            ? lower.GetString()
            : body.GetProperty("AccessToken").GetString();
        return token ?? string.Empty;
    }

    public static async Task<string> GetVerificationTokenFromDb(
        this CustomWebApplicationFactory factory, string email)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email.ToLower());
        return user.EmailVerificationToken!;
    }

    public static async Task<string> GetPasswordResetTokenFromDb(
        this CustomWebApplicationFactory factory, string email)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email.ToLower());
        return user.PasswordResetToken!;
    }
}
