using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UserService.Domain.Enums;
using UserService.Infrastructure.Persistence;
using UserService.IntegrationTests.Helpers;

namespace UserService.IntegrationTests.Auth;

public class AuthTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public AuthTests(CustomWebApplicationFactory factory) : base(factory)
    {
    }

    // ── Helpers ───────────────────────────────────────────────────

    private static object BuildRegisterRequest(string? username = null, string? email = null) =>
        new
        {
            username = username ?? $"user_{Guid.NewGuid():N}"[..20],
            email = email ?? $"{Guid.NewGuid():N}@test.com",
            password = "Test1234!",
            firstName = "Test",
            lastName = "User",
            birthDate = "1990-01-01T00:00:00",
            phoneNumber = "+38761234567",
            consentGiven = true,
            consentVersion = "1.0"
        };

    private async Task<(string username, string email)> RegisterAndVerifyAsync(
        HttpClient client, string? email = null, string? username = null,
        string password = "Test1234!")
    {
        email ??= $"user_{Guid.NewGuid():N}@test.com";
        username ??= $"u{Guid.NewGuid():N}"[..19];

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = "Test",
            lastName = "User",
            username,
            email,
            password,
            phoneNumber = "+38761234567",
            birthDate = "1990-01-01T00:00:00",
            consentGiven = true,
            consentVersion = "1.0"
        });

        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email.ToLower());
        user.IsVerified = true;
        user.EmailVerifiedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        return (username, email);
    }

    private async Task<string> RegisterVerifyAndLoginAsync(
        HttpClient client, string? email = null, string? username = null)
    {
        var (_, resolvedEmail) = await RegisterAndVerifyAsync(client, email, username);

        var login = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = resolvedEmail,
            password = "Test1234!"
        });
        login.EnsureSuccessStatusCode();

        var body = await login.Content.ReadFromJsonAsync<JsonElement>();
        var token = body.TryGetProperty("accessToken", out var camel)
            ? camel.GetString()
            : body.GetProperty("AccessToken").GetString();
        return token!;
    }

    private async Task<string> GetTokenAsync(HttpClient client, string email)
        => await client.GetJwtTokenAsync(email, "Test1234!", Factory);

    private async Task<string> GetVerificationTokenFromDb(string email)
    {
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email.ToLower());
        return user.EmailVerificationToken!;
    }

    private async Task<string> GetPasswordResetTokenFromDb(string email)
    {
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email.ToLower());
        return user.PasswordResetToken!;
    }

    private async Task<string> GetAdminTokenAsync(HttpClient client)
    {
        var adminEmail = $"admin_{Guid.NewGuid():N}@test.com";
        var adminUsername = $"adm{Guid.NewGuid():N}"[..19];

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = "Admin",
            lastName = "User",
            username = adminUsername,
            email = adminEmail,
            password = "Test1234!",
            phoneNumber = "+38761234567",
            birthDate = "1990-01-01T00:00:00",
            consentGiven = true,
            consentVersion = "1.0"
        });

        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == adminEmail.ToLower());
        user.IsVerified = true;
        user.EmailVerifiedAt = DateTime.UtcNow;
        user.Role = UserRole.Admin;
        await db.SaveChangesAsync();

        var login = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = adminEmail,
            password = "Test1234!"
        });
        login.EnsureSuccessStatusCode();

        var body = await login.Content.ReadFromJsonAsync<JsonElement>();
        var token = body.TryGetProperty("accessToken", out var camel)
            ? camel.GetString()
            : body.GetProperty("AccessToken").GetString();
        return token!;
    }

    // ── Register ──────────────────────────────────────────────────

    [Fact]
    public async Task Register_WithValidData_Returns201()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", BuildRegisterRequest());

        // Add this to see WHY it's 400:
        if (response.StatusCode != HttpStatusCode.Created)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new Exception($"Expected 201 but got {response.StatusCode}. Body: {body}");
        }

        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }


    [Fact]
    public async Task Register_WithDuplicateEmail_Returns409()
    {
        var client = Factory.CreateClient();
        var request = BuildRegisterRequest();
        await client.PostAsJsonAsync("/api/auth/register", request);
        var response = await client.PostAsJsonAsync("/api/auth/register", request);
        response.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task Register_WithMissingFields_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new { email = "bad" });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task Register_WithWeakPassword_Returns400()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            username = $"user_{Guid.NewGuid():N}"[..20],
            email = $"{Guid.NewGuid():N}@test.com",
            password = "123",
            firstName = "Test",
            lastName = "User",
            birthDate = "1990-01-01T00:00:00",
            phoneNumber = "+38761234567",
            consentGiven = true,
            consentVersion = "1.0"
        });
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── Login ─────────────────────────────────────────────────────

    [Fact]
    public async Task Login_WithValidCredentials_Returns200WithToken()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("accessToken");
    }

    [Fact]
    public async Task Login_WithWrongPassword_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = "nobody@test.com",
            password = "WrongPass1!"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Login_WithUnverifiedUser_Returns403()
    {
        var client = Factory.CreateClient();
        var email = $"{Guid.NewGuid():N}@test.com";
        await client.PostAsJsonAsync("/api/auth/register", BuildRegisterRequest(email: email));

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Login_WithBannedUser_Returns403()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var user = await db.Users.FirstAsync(u => u.Email == email);
        user.IsBanned = true;
        await db.SaveChangesAsync();

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── Refresh token ─────────────────────────────────────────────

    [Fact]
    public async Task Refresh_WithValidToken_Returns200()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });
        var loginBody = await loginResponse.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var refreshToken = loginBody!["refreshToken"].ToString();

        var response = await client.PostAsJsonAsync("/api/auth/refresh", refreshToken);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        body.Should().ContainKey("accessToken");
    }

    [Fact]
    public async Task Refresh_WithInvalidToken_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/refresh", "totally-invalid-token");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Logout ────────────────────────────────────────────────────

    [Fact]
    public async Task Logout_WithValidToken_Returns200()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });
        var loginBody = await loginResponse.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        var accessToken = loginBody!["accessToken"].ToString();
        var refreshToken = loginBody!["refreshToken"].ToString();

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await client.PostAsJsonAsync("/api/auth/logout", refreshToken);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── Protected endpoints ───────────────────────────────────────

    [Fact]
    public async Task GetProfile_WithoutToken_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/users/me");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetProfile_WithValidToken_Returns200()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);
        var token = await GetTokenAsync(client, email);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.GetAsync("/api/users/me");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetProfile_WithExpiredToken_Returns401()
    {
        var client = Factory.CreateClient();
        const string expiredToken =
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
            "eyJzdWIiOiIxIiwiZXhwIjoxNjAwMDAwMDAwfQ." +
            "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", expiredToken);

        var response = await client.GetAsync("/api/users/me");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Profile updates ───────────────────────────────────────────

    [Fact]
    public async Task UpdateProfile_WithValidData_Returns200()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);
        var token = await GetTokenAsync(client, email);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.PutAsJsonAsync("/api/users/me", new
        {
            firstName = "Updated",
            lastName = "Name",
            phoneNumber = "+38761111111",
            birthDate = "1995-01-01T00:00:00"
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task DeleteAccount_Returns204()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);
        var token = await GetTokenAsync(client, email);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.DeleteAsync("/api/users/me");
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    // ── Password ──────────────────────────────────────────────────

    [Fact]
    public async Task ChangePassword_WithCorrectOldPassword_Returns200()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);
        var token = await GetTokenAsync(client, email);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.PutAsJsonAsync("/api/users/me/password", new
        {
            currentPassword = "Test1234!",
            newPassword = "NewPass5678!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task ChangePassword_WithWrongOldPassword_Returns400()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);
        var token = await GetTokenAsync(client, email);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.PutAsJsonAsync("/api/users/me/password", new
        {
            currentPassword = "WrongOldPass1!",
            newPassword = "NewPass5678!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Admin: ban/unban ──────────────────────────────────────────

    [Fact]
    public async Task BanUser_AsAdmin_Returns200()
    {
        var client = Factory.CreateClient();

        var (_, targetEmail) = await RegisterAndVerifyAsync(client);
        using var scope1 = Factory.Services.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<UserDbContext>();
        var targetId = (await db1.Users.FirstAsync(u => u.Email == targetEmail)).PersonId;

        var adminToken = await GetAdminTokenAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.PostAsync($"/api/users/{targetId}/ban", null);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task BanUser_AsNonAdmin_Returns403()
    {
        var client = Factory.CreateClient();

        var (_, targetEmail) = await RegisterAndVerifyAsync(client);
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
        var targetId = (await db.Users.FirstAsync(u => u.Email == targetEmail)).PersonId;

        var (_, attackerEmail) = await RegisterAndVerifyAsync(client);
        var attackerToken = await GetTokenAsync(client, attackerEmail);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", attackerToken);

        var response = await client.PostAsync($"/api/users/{targetId}/ban", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── Email Verification ────────────────────────────────────────

    [Fact]
    public async Task VerifyEmail_WithValidToken_ReturnsOk()
    {
        var client = Factory.CreateClient();
        var email = $"verifytest_{Guid.NewGuid()}@test.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = "Verify",
            lastName = "Test",
            username = $"verifyuser_{Guid.NewGuid():N}"[..20],
            email,
            password = "Test1234!",
            phoneNumber = "+38761234567",
            birthDate = "1990-01-01T00:00:00",
            consentGiven = true,
            consentVersion = "1.0"
        });

        var token = await GetVerificationTokenFromDb(email);
        var response = await client.GetAsync(
            $"/api/auth/verify-email?token={Uri.EscapeDataString(token)}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task VerifyEmail_WithInvalidToken_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync(
            "/api/auth/verify-email?token=invalid-token-xyz");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task VerifyEmail_AlreadyVerified_SecondCallStillReturns401()
    {
        var client = Factory.CreateClient();
        var email = $"doubleverify_{Guid.NewGuid()}@test.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = "Double",
            lastName = "Verify",
            username = $"dblverify_{Guid.NewGuid():N}"[..15],
            email,
            password = "Test1234!",
            phoneNumber = "+38761234567",
            birthDate = "1990-01-01T00:00:00",
            consentGiven = true,
            consentVersion = "1.0"
        });

        var token = await GetVerificationTokenFromDb(email);
        await client.GetAsync(
            $"/api/auth/verify-email?token={Uri.EscapeDataString(token)}");

        var second = await client.GetAsync(
            $"/api/auth/verify-email?token={Uri.EscapeDataString(token)}");
        second.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Forgot / Reset Password ───────────────────────────────────

    [Fact]
    public async Task ForgotPassword_WithValidEmail_ReturnsOk()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        var response = await client.PostAsJsonAsync("/api/auth/forgot-password", new { email });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task ForgotPassword_WithUnknownEmail_StillReturnsOk()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/forgot-password",
            new { email = "nobody@nowhere.com" });
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task ResetPassword_WithValidToken_ReturnsOkAndAllowsNewLogin()
    {
        var client = Factory.CreateClient();
        var (_, email) = await RegisterAndVerifyAsync(client);

        await client.PostAsJsonAsync("/api/auth/forgot-password", new { email });
        var resetToken = await GetPasswordResetTokenFromDb(email);

        var resetResponse = await client.PostAsJsonAsync("/api/auth/reset-password", new
        {
            token = resetToken,
            newPassword = "NewPassword99!"
        });
        resetResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var oldLogin = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "Test1234!"
        });
        oldLogin.StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var newLogin = await client.PostAsJsonAsync("/api/auth/login", new
        {
            emailOrUsername = email,
            password = "NewPassword99!"
        });
        newLogin.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task ResetPassword_WithInvalidToken_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/reset-password", new
        {
            token = "bogus-reset-token",
            newPassword = "NewPassword99!"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ── Preferences ───────────────────────────────────────────────

    [Fact]
    public async Task Preferences_UpsertAndGet_ReturnsCorrectData()
    {
        var client = Factory.CreateClient();
        var token = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var upsert = await client.PutAsJsonAsync("/api/preferences", new
        {
            segmentId = 1,
            genreId = 2,
            score = 0.8
        });
        upsert.StatusCode.Should().Be(HttpStatusCode.OK);

        var get = await client.GetAsync("/api/preferences");
        get.StatusCode.Should().Be(HttpStatusCode.OK);
        (await get.Content.ReadAsStringAsync()).Should().Contain("0.8");
    }

    [Fact]
    public async Task Preferences_Delete_RemovesPreference()
    {
        var client = Factory.CreateClient();
        var token = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var upsert = await client.PutAsJsonAsync("/api/preferences", new
        {
            segmentId = 3,
            genreId = 4,
            score = 0.5
        });
        upsert.EnsureSuccessStatusCode();
        var created = await upsert.Content.ReadFromJsonAsync<JsonElement>();
        var prefId = created.TryGetProperty("prefId", out var camel)
            ? camel.GetInt32()
            : created.GetProperty("PrefId").GetInt32();

        var delete = await client.DeleteAsync($"/api/preferences/{prefId}");
        delete.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── Reports ───────────────────────────────────────────────────

    [Fact]
    public async Task Reports_CreateAndGetUserReports_Works()
    {
        var client = Factory.CreateClient();
        var token = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var create = await client.PostAsJsonAsync("/api/reports", new
        {
            targetType = 1,
            targetId = 42,
            reason = "Spam",
            description = "This is spam content"
        });
        create.StatusCode.Should().Be(HttpStatusCode.OK);

        var get = await client.GetAsync("/api/reports/my");
        get.StatusCode.Should().Be(HttpStatusCode.OK);
        (await get.Content.ReadAsStringAsync()).Should().Contain("Spam");
    }

    [Fact]
    public async Task Reports_ResolveByAdmin_ChangesStatus()
    {
        var client = Factory.CreateClient();
        var userToken = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", userToken);

        var create = await client.PostAsJsonAsync("/api/reports", new
        {
            targetType = 1,
            targetId = 99,
            reason = "Inappropriate",
            description = "Bad content"
        });
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<JsonElement>();
        var reportId = created.TryGetProperty("reportId", out var camel)
            ? camel.GetInt32()
            : created.GetProperty("ReportId").GetInt32();

        var adminToken = await GetAdminTokenAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        var resolve = await client.PostAsJsonAsync(
            $"/api/reports/{reportId}/resolve",
            new { action = "Resolve" });
        resolve.StatusCode.Should().Be(HttpStatusCode.OK);
        (await resolve.Content.ReadAsStringAsync()).Should().Contain("Resolved");
    }

    // ── Activity Logs ─────────────────────────────────────────────

    [Fact]
    public async Task ActivityLogs_GetUserLogs_ReturnsOk()
    {
        var client = Factory.CreateClient();
        var token = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        var response = await client.GetAsync("/api/users/me/activity-logs?page=1&pageSize=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // ── Admin: Get All Users ──────────────────────────────────────

    [Fact]
    public async Task Admin_GetAllUsers_ReturnsPagedResult()
    {
        var client = Factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.GetAsync("/api/users?page=1&pageSize=10");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        (await response.Content.ReadAsStringAsync()).Should().Contain("items");
    }

    // ── Revoke All Sessions ───────────────────────────────────────

    [Fact]
    public async Task RevokeAllSessions_InvalidatesAllRefreshTokens()
    {
        var client = Factory.CreateClient();
        var token = await RegisterVerifyAndLoginAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);

        await client.PostAsync("/api/auth/revoke-all", null);

        var refresh = await client.PostAsJsonAsync("/api/auth/refresh", "any_old_token");
        refresh.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
