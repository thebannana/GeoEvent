using UserService.Domain.Enums;

namespace UserService.Domain.Entities;

public class User
{
    public int PersonId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public byte[] PasswordHash { get; set; } = [];
    public byte[] PasswordSalt { get; set; } = [];
    public UserRole Role { get; set; } = UserRole.User;
    public bool IsVerified { get; set; } = false;
    public bool IsBanned { get; set; } = false;
    public DateTime CreatedAt { get; set; }
    public string? EmailVerificationToken { get; set; }
    public DateTime? EmailVerificationTokenExpiresAt { get; set; }
    public DateTime? EmailVerifiedAt { get; set; }
    public string? PasswordResetToken { get; set; }
    public DateTime? PasswordResetTokenExpiresAt { get; set; }


    // Security
    public int FailedLoginAttempts { get; set; } = 0;
    public DateTime? LockoutUntil { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public string? LastLoginIp { get; set; }

    // GDPR
    public DateTime? ConsentGivenAt { get; set; }
    public string? ConsentVersion { get; set; }

    // Navigation
    public Person? Person { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<ActivityLog> ActivityLogs { get; set; } = [];
    public ICollection<UserPreference> Preferences { get; set; } = [];
    public ICollection<Report> FiledReports { get; set; } = [];
    public ICollection<Report> ResolvedReports { get; set; } = [];


    // Domain logic
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
        FailedLoginAttempts = 0;
        LockoutUntil = null;
        LastLoginAt = DateTime.UtcNow;
        LastLoginIp = ipAddress;
    }

    public void SoftDelete()
    {
        Person!.IsDeleted = true;
        Person.DeletedAt = DateTime.UtcNow;
    }

    public bool IsEmailVerificationTokenValid(string token) =>
    EmailVerificationToken == token &&
    EmailVerificationTokenExpiresAt.HasValue &&
    DateTime.UtcNow < EmailVerificationTokenExpiresAt.Value;

    public bool IsPasswordResetTokenValid(string token) =>
        PasswordResetToken == token &&
        PasswordResetTokenExpiresAt.HasValue &&
        DateTime.UtcNow < PasswordResetTokenExpiresAt.Value;

    public void VerifyEmail()
    {
        IsVerified = true;
        EmailVerifiedAt = DateTime.UtcNow;
        EmailVerificationToken = null;
        EmailVerificationTokenExpiresAt = null;
    }

}
