namespace UserService.Domain.Entities;

public class PasswordResetToken
{
    public long Id { get; private set; }
    public int UserId { get; private set; }
    public string TokenHash { get; private set; } = string.Empty;
    public DateTime CreatedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public DateTime? UsedAt { get; private set; }

    public User User { get; private set; } = null!;

    private PasswordResetToken() { }

    public PasswordResetToken(int userId, string tokenHash, DateTime createdAt, DateTime expiresAt)
    {
        if (userId <= 0)
            throw new ArgumentException("User ID must be greater than zero.", nameof(userId));

        if (string.IsNullOrWhiteSpace(tokenHash))
            throw new ArgumentException("Token hash is required.", nameof(tokenHash));

        if (expiresAt <= createdAt)
            throw new ArgumentException("Expiration time must be after creation time.", nameof(expiresAt));

        UserId = userId;
        TokenHash = tokenHash;
        CreatedAt = createdAt;
        ExpiresAt = expiresAt;
    }

    public bool IsExpired() => DateTime.UtcNow >= ExpiresAt;

    public bool IsUsed() => UsedAt.HasValue;

    public bool IsActive() => !IsExpired() && !IsUsed();

    public void MarkAsUsed()
    {
        if (IsUsed())
            throw new InvalidOperationException("Password reset token has already been used.");

        if (IsExpired())
            throw new InvalidOperationException("Password reset token has expired.");

        UsedAt = DateTime.UtcNow;
    }

    public void Invalidate()
    {
        if (!IsUsed())
            UsedAt = DateTime.UtcNow;
    }
}