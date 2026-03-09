using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Persistence.Configurations;

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("RefreshTokens");
        builder.HasKey(r => r.TokenId);

        builder.Property(r => r.TokenHash).IsRequired().HasMaxLength(500);
        builder.Property(r => r.DeviceInfo).HasMaxLength(200);
        builder.Property(r => r.IpAddress).HasMaxLength(45);

        builder.HasIndex(r => r.TokenHash).IsUnique();
        builder.HasIndex(r => r.ExpiresAt);
        builder.HasIndex(r => r.RevokedAt);
        builder.HasIndex(r => new { r.UserId, r.RevokedAt });

        builder.HasOne(r => r.User)
            .WithMany(u => u.RefreshTokens)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
