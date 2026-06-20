namespace UserService.Domain.Entities;

public class RefreshToken
{
    public int TokenId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? DeviceInfo { get; set; }
    public string? IpAddress { get; set; }

    public User? User { get; set; }

    public bool IsExpired() => DateTime.UtcNow >= ExpiresAt;
    public bool IsRevoked() => RevokedAt.HasValue;
    public bool IsActive() => !IsExpired() && !IsRevoked();

    public void Revoke() => RevokedAt = DateTime.UtcNow;
}
