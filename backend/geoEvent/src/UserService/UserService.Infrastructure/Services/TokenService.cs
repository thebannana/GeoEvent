using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UserService.Domain.Entities;
using UserService.Infrastructure.Options;

namespace UserService.Infrastructure.Services;

public class TokenService
{
    private readonly JwtOptions _options;
    private readonly SigningCredentials _signingCredentials;

    public TokenService(IOptions<JwtOptions> options)
    {
        _options = options.Value;

        if (string.IsNullOrWhiteSpace(_options.Secret))
            throw new InvalidOperationException("JWT secret is not configured.");

        if (string.IsNullOrWhiteSpace(_options.Issuer))
            throw new InvalidOperationException("JWT issuer is not configured.");

        if (string.IsNullOrWhiteSpace(_options.Audience))
            throw new InvalidOperationException("JWT audience is not configured.");

        if (_options.ExpiryMinutes <= 0)
            throw new InvalidOperationException("JWT expiry minutes must be greater than zero.");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Secret));
        _signingCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);
    }

    public string GenerateAccessToken(User user)
    {
        ArgumentNullException.ThrowIfNull(user);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.PersonId.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes),
            signingCredentials: _signingCredentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public static (string raw, string hash) GenerateRefreshToken()
    {
        var raw = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var hash = Convert.ToBase64String(
            SHA256.HashData(Encoding.UTF8.GetBytes(raw)));

        return (raw, hash);
    }
}