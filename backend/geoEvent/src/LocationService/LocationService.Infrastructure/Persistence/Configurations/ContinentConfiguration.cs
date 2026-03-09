using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Persistence.Configurations;

public class ContinentConfiguration : IEntityTypeConfiguration<Continent>
{
    public void Configure(EntityTypeBuilder<Continent> builder)
    {
        builder.HasKey(c => c.ContinentId);

        builder.Property(c => c.ContinentName)
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(c => c.ContinentCode)
            .HasMaxLength(10)
            .IsRequired();

        builder.HasIndex(c => c.ContinentCode).IsUnique();
        builder.HasIndex(c => c.ContinentName);
    }
}
