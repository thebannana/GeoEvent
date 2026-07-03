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
    public bool IsBanned { get; set; } = false;
    public DateTime CreatedAt { get; set; }

    public int FailedLoginAttempts { get; set; } = 0;
    public DateTime? LockoutUntil { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public string? LastLoginIp { get; set; }

    public DateTime? ConsentGivenAt { get; set; }
    public string? ConsentVersion { get; set; }

    public bool HasPayPalConnected { get; set; } = false;
    public string? PayPalMerchantId { get; set; }
    public string? PayPalEmail { get; set; }
    public string? PayPalConnectionStatus { get; set; }
    public string? PayPalTrackingId { get; set; }
    public DateTime? PayPalConnectedAt { get; set; }

    public Person? Person { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<UserPreference> Preferences { get; set; } = [];
    public ICollection<Report> FiledReports { get; set; } = [];
    public ICollection<Report> ResolvedReports { get; set; } = [];
    public ICollection<PasswordResetToken> PasswordResetTokens { get; set; } = new List<PasswordResetToken>();

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
        if (Person is null)
            throw new InvalidOperationException("Cannot soft delete user without person profile.");

        Person.IsDeleted = true;
        Person.DeletedAt = DateTime.UtcNow;
    }

    public void ConnectPayPal(string merchantId, string? email, string? status, string? trackingId = null)
    {
        HasPayPalConnected = true;
        PayPalMerchantId = merchantId?.Trim();
        PayPalEmail = string.IsNullOrWhiteSpace(email) ? null : email.Trim();
        PayPalConnectionStatus = string.IsNullOrWhiteSpace(status) ? "connected" : status.Trim();
        PayPalTrackingId = string.IsNullOrWhiteSpace(trackingId) ? PayPalTrackingId : trackingId.Trim();
        PayPalConnectedAt = DateTime.UtcNow;
    }

    public void StartPayPalOnboarding(string trackingId)
    {
        PayPalTrackingId = trackingId.Trim();
        HasPayPalConnected = false;
        PayPalConnectionStatus = "pending";
    }

    public void DisconnectPayPal()
    {
        HasPayPalConnected = false;
        PayPalMerchantId = null;
        PayPalEmail = null;
        PayPalTrackingId = null;
        PayPalConnectedAt = null;
        PayPalConnectionStatus = "not_connected";
    }
}