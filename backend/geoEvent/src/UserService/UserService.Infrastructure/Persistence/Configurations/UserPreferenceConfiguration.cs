using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Persistence.Configurations;

public class UserPreferenceConfiguration : IEntityTypeConfiguration<UserPreference>
{
    public void Configure(EntityTypeBuilder<UserPreference> builder)
    {
        builder.HasKey(p => p.PrefId);

        builder.Property(p => p.Score)
            .HasDefaultValue(0.0);

        builder.Property(p => p.LastUpdated)
            .HasDefaultValueSql("GETUTCDATE()");

        builder.HasOne(p => p.User)
            .WithMany(u => u.Preferences)
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => p.UserId);
        builder.HasIndex(p => p.SegmentId);
        builder.HasIndex(p => p.GenreId);
        builder.HasIndex(p => p.SubGenreId);

        builder.HasIndex(p => new { p.UserId, p.SegmentId, p.GenreId, p.SubGenreId })
            .IsUnique()
            .HasFilter("[UserId] IS NOT NULL");
    }
}