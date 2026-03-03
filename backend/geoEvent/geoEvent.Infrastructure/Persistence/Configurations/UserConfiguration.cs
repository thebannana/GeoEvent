using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.HasIndex(u => u.Username).IsUnique();
            builder.HasIndex(u => u.Email).IsUnique();
            builder.HasIndex(u => u.CreatedAt);
            builder.HasIndex(u => u.Role);
            builder.HasIndex(u => u.IsDeleted);
            builder.HasIndex(u => u.LockoutUntil);

            builder.Property(u => u.Username).HasMaxLength(50).IsRequired();
            builder.Property(u => u.Email).HasMaxLength(255).IsRequired();
            builder.Property(u => u.Role).HasMaxLength(20).IsRequired();
            builder.Property(u => u.IsDeleted).HasDefaultValue(false);
            builder.Property(u => u.FailedLoginAttempts).HasDefaultValue(0);
            builder.Property(u => u.ConsentVersion).HasMaxLength(20);
            builder.Property(u => u.LastLoginIp).HasMaxLength(45);
        }
    }
}