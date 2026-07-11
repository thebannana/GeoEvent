using System.Security.Cryptography;

namespace UserService.Infrastructure.Services;

public class PasswordService
{
    private const int SaltSize = 16;
    private const int HashSize = 32;
    private const int Iterations = 100_000;

    public (byte[] hash, byte[] salt) HashPassword(string password)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);

        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            HashSize);

        return (hash, salt);
    }

    public bool VerifyPassword(string password, byte[] hash, byte[] salt)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);

        if (hash is null || hash.Length == 0)
            return false;

        if (salt is null || salt.Length == 0)
            return false;

        var computed = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            hash.Length);

        return CryptographicOperations.FixedTimeEquals(computed, hash);
    }
}