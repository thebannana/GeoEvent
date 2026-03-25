using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace LocationService.IntegrationTests.Helpers;

public static class HttpClientExtensions
{
    public static string GenerateJwt(
        int userId,
        string role = "User",
        string secret = "ThisIsAVeryLongSecretKeyUsedOnlyForIntegrationTestingPurposesXYZ123!!")
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Role, role),
            new Claim(ClaimTypes.Email, $"user{userId}@test.com"),
            new Claim(ClaimTypes.Name, $"user{userId}"),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha512Signature);

        var token = new JwtSecurityToken(
            issuer: "geoEvent.UserService",
            audience: "geoEvent.Client",
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
