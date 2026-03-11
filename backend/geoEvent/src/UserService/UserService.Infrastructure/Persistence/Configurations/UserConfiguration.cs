using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        builder.HasKey(u => u.PersonId);

        builder.HasQueryFilter(u => !u.Person!.IsDeleted);

        builder.Property(u => u.Username).IsRequired().HasMaxLength(50);
        builder.Property(u => u.Email).IsRequired().HasMaxLength(255);
        builder.Property(u => u.Role).HasConversion<string>().HasMaxLength(20);
        builder.Property(u => u.LastLoginIp).HasMaxLength(45);
        builder.Property(u => u.ConsentVersion).HasMaxLength(20);
        builder.Property(u => u.FailedLoginAttempts).HasDefaultValue(0);
        builder.Property(u => u.EmailVerificationToken).HasMaxLength(512);
        builder.Property(u => u.PasswordResetToken).HasMaxLength(512);

        builder.HasIndex(u => u.EmailVerificationToken)
            .HasFilter("[EmailVerificationToken] IS NOT NULL");
        builder.HasIndex(u => u.PasswordResetToken)
            .HasFilter("[PasswordResetToken] IS NOT NULL");

        builder.HasIndex(u => u.Email).IsUnique();
        builder.HasIndex(u => u.Username).IsUnique();
        builder.HasIndex(u => u.LockoutUntil);

        builder.HasOne(u => u.Person)
            .WithOne(p => p.User)
            .HasForeignKey<User>(u => u.PersonId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
