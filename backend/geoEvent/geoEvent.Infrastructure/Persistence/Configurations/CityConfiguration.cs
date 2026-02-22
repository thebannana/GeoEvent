using geoEvent.Model.Models;
using MathNet.Numerics.Statistics.Mcmc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class CityConfiguration : IEntityTypeConfiguration<City>
    {
        public void Configure(EntityTypeBuilder<City> builder)
        {
            builder.HasKey(c => c.CityId);

            builder.HasOne(c => c.Division)
               .WithMany()
               .HasForeignKey(c => c.DivisionId)
            .OnDelete(DeleteBehavior.Restrict);

            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");

            builder.HasIndex(c => c.DivisionId);
            builder.HasIndex(c => c.CityName);
            builder.HasIndex(c => c.NormalizedName);

            builder.Property(c => c.CityName).HasMaxLength(255).IsRequired();
            builder.Property(c => c.NormalizedName).HasMaxLength(255).IsRequired();
        }
    }
}