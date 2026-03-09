using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Persistence.Configurations;

public class AdministrativeDivisionConfiguration : IEntityTypeConfiguration<AdministrativeDivision>
{
    public void Configure(EntityTypeBuilder<AdministrativeDivision> builder)
    {
        builder.HasKey(a => a.DivisionId);

        builder.Property(a => a.DivisionName)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(a => a.DivisionCode)
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(a => a.DivisionType)
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(a => a.Latitude)
            .HasColumnType("decimal(9,6)");

        builder.Property(a => a.Longitude)
            .HasColumnType("decimal(9,6)");

        builder.HasOne(a => a.Country)
            .WithMany(c => c.Divisions)
            .HasForeignKey(a => a.CountryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.ParentDivision)
            .WithMany(a => a.ChildDivisions)
            .HasForeignKey(a => a.ParentDivisionId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(a => a.CountryId);
        builder.HasIndex(a => a.ParentDivisionId);
        builder.HasIndex(a => a.DivisionCode);
        builder.HasIndex(a => a.Level);
        builder.HasIndex(a => a.IsActive);
        builder.HasIndex(a => new { a.CountryId, a.Level });
    }
}
