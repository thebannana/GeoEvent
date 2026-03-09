using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Persistence.Configurations;

public class PostalCodeConfiguration : IEntityTypeConfiguration<PostalCode>
{
    public void Configure(EntityTypeBuilder<PostalCode> builder)
    {
        builder.HasKey(p => p.PostalCodeId);

        builder.Property(p => p.Code)
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(p => p.Latitude)
            .HasColumnType("decimal(9,6)");

        builder.Property(p => p.Longitude)
            .HasColumnType("decimal(9,6)");

        builder.HasOne(p => p.City)
            .WithMany(c => c.PostalCodes)
            .HasForeignKey(p => p.CityId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(p => p.Code);
        builder.HasIndex(p => p.CityId);
        builder.HasIndex(p => new { p.Code, p.CityId });
    }
}
