using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FluentAssertions;
using Microsoft.IdentityModel.Tokens;

namespace Security.Tests;

public class JwtSecurityTests
{
    private const string ValidSecret =
        "geoEvent_SuperSecret_JWT_Key_2026_ThisMustBeAtLeast64CharactersLongForSHA512!!";
    private const string ValidIssuer = "GeoEvent";
    private const string ValidAudience = "GeoEventUsers";

    private static string GenerateToken(
        string secret = ValidSecret,
        string issuer = ValidIssuer,
        string audience = ValidAudience,
        int expiryMinutes = 15,
        IEnumerable<Claim>? extraClaims = null)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret))
        {
            KeyId = "geoevent-key"
        };
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "1"),
            new(ClaimTypes.Role, "User"),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        if (extraClaims != null) claims.AddRange(extraClaims);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static TokenValidationParameters GetValidationParams(string? secret = null) =>
        new()
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = ValidIssuer,
            ValidAudience = ValidAudience,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(secret ?? ValidSecret)),
            ClockSkew = TimeSpan.Zero
        };

    // ── Valid token ───────────────────────────────────────────────

    [Fact]
    public void ValidToken_PassesValidation()
    {
        var token = GenerateToken();
        var handler = new JwtSecurityTokenHandler();

        var act = () => handler.ValidateToken(token, GetValidationParams(), out _);

        act.Should().NotThrow();
    }

    [Fact]
    public void ValidToken_ContainsCorrectIssuerAndAudience()
    {
        var token = GenerateToken();
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        jwt.Issuer.Should().Be(ValidIssuer);
        jwt.Audiences.Should().Contain(ValidAudience);
    }

    [Fact]
    public void ValidToken_IsNotExpiredOnCreation()
    {
        var token = GenerateToken();
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        jwt.ValidTo.Should().BeAfter(DateTime.UtcNow);
    }

    [Fact]
    public void ValidToken_ContainsUserIdClaim()
    {
        var token = GenerateToken();
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        jwt.Claims.Should().Contain(c =>
            c.Type == ClaimTypes.NameIdentifier && c.Value == "1");
    }

    [Fact]
    public void ValidToken_ContainsUniqueJti()
    {
        var token1 = GenerateToken();
        var token2 = GenerateToken();

        var jti1 = new JwtSecurityTokenHandler().ReadJwtToken(token1)
            .Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value;
        var jti2 = new JwtSecurityTokenHandler().ReadJwtToken(token2)
            .Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value;

        jti1.Should().NotBe(jti2);
    }

    // ── Tampered / invalid tokens ─────────────────────────────────

    [Fact]
    public void TamperedPayload_FailsValidation()
    {
        var token = GenerateToken();
        var parts = token.Split('.');
        var tamperedPayload = parts[1][..^1] + (parts[1][^1] == 'A' ? 'B' : 'A');
        var tamperedToken = $"{parts[0]}.{tamperedPayload}.{parts[2]}";

        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken(tamperedToken, GetValidationParams(), out _);

        // ArgumentException wraps the decode failure before signature check
        act.Should().Throw<Exception>()
            .WithMessage("*Unable to decode*");
    }

    [Fact]
    public void WrongSigningKey_FailsValidation()
    {
        var token = GenerateToken();
        var wrongKeyParams = GetValidationParams("WrongKey_ThatIsDefinitelyNotTheRealSecret_And64CharsLong!!!!!!!!");

        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken(token, wrongKeyParams, out _);

        act.Should().Throw<SecurityTokenSignatureKeyNotFoundException>();
    }

    [Fact]
    public void ExpiredToken_FailsValidation()
    {
        var token = GenerateToken(expiryMinutes: -1);

        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken(token, GetValidationParams(), out _);

        act.Should().Throw<SecurityTokenExpiredException>();
    }

    [Fact]
    public void WrongIssuer_FailsValidation()
    {
        var token = GenerateToken(issuer: "evil-issuer");

        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken(token, GetValidationParams(), out _);

        act.Should().Throw<SecurityTokenInvalidIssuerException>();
    }

    [Fact]
    public void WrongAudience_FailsValidation()
    {
        var token = GenerateToken(audience: "wrong-audience");

        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken(token, GetValidationParams(), out _);

        act.Should().Throw<SecurityTokenInvalidAudienceException>();
    }

    [Fact]
    public void MalformedToken_FailsValidation()
    {
        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken("not.a.valid.jwt.token", GetValidationParams(), out _);

        // ArgumentException is thrown for malformed Base64Url headers
        act.Should().Throw<Exception>()
            .WithMessage("*Unable to decode*");
    }


    [Fact]
    public void EmptyToken_FailsValidation()
    {
        var handler = new JwtSecurityTokenHandler();
        var act = () => handler.ValidateToken("", GetValidationParams(), out _);

        act.Should().Throw<Exception>();
    }

    // ── Algorithm / key strength ──────────────────────────────────

    [Fact]
    public void Token_UsesHmacSha256Algorithm()
    {
        var token = GenerateToken();
        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);

        jwt.Header.Alg.Should().Be(SecurityAlgorithms.HmacSha256);
    }

    [Fact]
    public void ShortSecret_BelowMinimumLength_ShouldBeRejected()
    {
        // Secrets under 32 bytes are too weak for HMAC-SHA256
        var shortSecret = "tooshort";
        var act = () => new SymmetricSecurityKey(Encoding.UTF8.GetBytes(shortSecret))
            .KeySize.Should().BeGreaterThanOrEqualTo(256);

        act.Should().Throw<Exception>();
    }

    [Fact]
    public void ProductionSecret_MeetsMinimumKeyLength()
    {
        var keyBytes = Encoding.UTF8.GetBytes(ValidSecret);
        var key = new SymmetricSecurityKey(keyBytes);

        key.KeySize.Should().BeGreaterThanOrEqualTo(256,
            "JWT signing keys must be at least 256 bits for HMAC-SHA256");
    }
}
