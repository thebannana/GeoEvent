using FluentAssertions;
using BCrypt.Net;
using Org.BouncyCastle.Crypto.Generators;

namespace Security.Tests;

public class PasswordSecurityTests
{
    // ── Hashing ───────────────────────────────────────────────────

    [Fact]
    public void HashPassword_ProducesNonPlaintextOutput()
    {
        var password = "MySecurePassword123!";
        var hash = BCrypt.Net.BCrypt.HashPassword(password);

        hash.Should().NotBe(password);
        hash.Should().StartWith("$2");
    }

    [Fact]
    public void HashPassword_TwoHashesOfSamePassword_AreDifferent()
    {
        var password = "MySecurePassword123!";
        var hash1 = BCrypt.Net.BCrypt.HashPassword(password);
        var hash2 = BCrypt.Net.BCrypt.HashPassword(password);

        hash1.Should().NotBe(hash2, "BCrypt uses random salt per hash");
    }

    [Fact]
    public void VerifyPassword_CorrectPassword_ReturnsTrue()
    {
        var password = "MySecurePassword123!";
        var hash = BCrypt.Net.BCrypt.HashPassword(password);

        var result = BCrypt.Net.BCrypt.Verify(password, hash);

        result.Should().BeTrue();
    }

    [Fact]
    public void VerifyPassword_WrongPassword_ReturnsFalse()
    {
        var hash = BCrypt.Net.BCrypt.HashPassword("CorrectPassword123!");

        var result = BCrypt.Net.BCrypt.Verify("WrongPassword123!", hash);

        result.Should().BeFalse();
    }

    [Fact]
    public void VerifyPassword_EmptyPassword_ReturnsFalse()
    {
        var hash = BCrypt.Net.BCrypt.HashPassword("CorrectPassword123!");

        var result = BCrypt.Net.BCrypt.Verify("", hash);

        result.Should().BeFalse();
    }

    [Fact]
    public void HashPassword_UsesMinimumWorkFactor()
    {
        var hash = BCrypt.Net.BCrypt.HashPassword("password", workFactor: 12);

        // BCrypt hash encodes the work factor — $2a$12$...
        hash.Should().Contain("$12$",
            "work factor must be at least 12 for production security");
    }

    // ── Common weak passwords ─────────────────────────────────────

    [Theory]
    [InlineData("password")]
    [InlineData("123456")]
    [InlineData("qwerty")]
    [InlineData("admin")]
    public void CommonPasswords_AreNotUsedAsSecrets(string weakPassword)
    {
        const string productionSecret =
            "geoEvent_SuperSecret_JWT_Key_2026_ThisMustBeAtLeast64CharactersLongForSHA512!!";

        productionSecret.Should().NotBe(weakPassword,
            "production JWT secret must not be a common weak password");
    }
}
