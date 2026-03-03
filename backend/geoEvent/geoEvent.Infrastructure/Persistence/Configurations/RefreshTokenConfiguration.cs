using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
    {
        public void Configure(EntityTypeBuilder<RefreshToken> builder)
        {
            builder.HasKey(t => t.TokenId);

            builder.HasOne(t => t.User)
                   .WithMany()
                   .HasForeignKey(t => t.UserId)
                   .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(t => t.TokenHash).IsUnique();
            builder.HasIndex(t => t.UserId);
            builder.HasIndex(t => t.ExpiresAt);
            builder.HasIndex(t => t.RevokedAt);
            builder.HasIndex(t => new { t.UserId, t.RevokedAt });

            builder.Property(t => t.TokenHash).HasMaxLength(500).IsRequired();
            builder.Property(t => t.DeviceInfo).HasMaxLength(200);
            builder.Property(t => t.IpAddress).HasMaxLength(45);
        }
    }
}