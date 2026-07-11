using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class User
{
    public int PersonId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public byte[] PasswordHash { get; private set; } = [];
    public byte[] PasswordSalt { get; private set; } = [];
    public UserRole Role { get; private set; } = UserRole.User;
    public bool IsBanned { get; private set; }
    public DateTime CreatedAt { get; set; }

    public int FailedLoginAttempts { get; private set; }
    public DateTime? LockoutUntil { get; private set; }
    public DateTime? LastLoginAt { get; private set; }
    public string? LastLoginIp { get; private set; }

    public DateTime? ConsentGivenAt { get; private set; }
    public string? ConsentVersion { get; private set; }

    public Person? Person { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<UserPreference> Preferences { get; set; } = [];
    public ICollection<Report> FiledReports { get; set; } = [];
    public ICollection<Report> ResolvedReports { get; set; } = [];
    public ICollection<PasswordResetToken> PasswordResetTokens { get; set; } = [];

    public bool IsLockedOut() =>
        LockoutUntil.HasValue && LockoutUntil.Value > DateTime.UtcNow;

    public void RegisterFailedLogin()
    {
        FailedLoginAttempts++;

        if (FailedLoginAttempts >= 5)
            LockoutUntil = DateTime.UtcNow.AddMinutes(15);
    }

    public void RegisterSuccessfulLogin(string ipAddress)
    {
        if (string.IsNullOrWhiteSpace(ipAddress))
            throw new ArgumentException("IP address is required.", nameof(ipAddress));

        FailedLoginAttempts = 0;
        LockoutUntil = null;
        LastLoginAt = DateTime.UtcNow;
        LastLoginIp = ipAddress.Trim();
    }

    public void Ban()
    {
        IsBanned = true;
    }

    public void Unban()
    {
        IsBanned = false;
    }

    public void SetRole(UserRole role)
    {
        Role = role;
    }

    public void RecordConsent(string version)
    {
        if (string.IsNullOrWhiteSpace(version))
            throw new ArgumentException("Consent version is required.", nameof(version));

        ConsentVersion = version.Trim();
        ConsentGivenAt = DateTime.UtcNow;
    }

    public void ChangePassword(byte[] passwordHash, byte[] passwordSalt)
    {
        if (passwordHash is null || passwordHash.Length == 0)
            throw new ArgumentException("Password hash is required.", nameof(passwordHash));

        if (passwordSalt is null || passwordSalt.Length == 0)
            throw new ArgumentException("Password salt is required.", nameof(passwordSalt));

        PasswordHash = passwordHash;
        PasswordSalt = passwordSalt;
    }

    public void SoftDelete()
    {
        if (Person is null)
            throw new InvalidOperationException("Cannot soft delete user without person profile.");

        Person.IsDeleted = true;
        Person.DeletedAt = DateTime.UtcNow;
    }
}