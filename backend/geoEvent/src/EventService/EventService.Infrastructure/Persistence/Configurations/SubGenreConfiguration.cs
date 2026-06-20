using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EventService.Infrastructure.Persistence.Configurations;

public class SubGenreConfiguration : IEntityTypeConfiguration<SubGenre>
{
    public void Configure(EntityTypeBuilder<SubGenre> builder)
    {
        builder.ToTable("SubGenres");

        builder.HasKey(s => s.SubGenreId);

        builder.Property(s => s.GenreId)
            .IsRequired();

        builder.Property(s => s.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(s => s.IsActive)
            .HasDefaultValue(true);

        builder.HasOne(s => s.Genre)
            .WithMany(g => g.SubGenres)
            .HasForeignKey(s => s.GenreId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(s => s.Name);
        builder.HasIndex(s => s.GenreId);
        builder.HasIndex(s => s.IsActive);
        builder.HasIndex(s => new { s.GenreId, s.IsActive });
        builder.HasIndex(s => new { s.GenreId, s.Name })
            .IsUnique();
    }
}