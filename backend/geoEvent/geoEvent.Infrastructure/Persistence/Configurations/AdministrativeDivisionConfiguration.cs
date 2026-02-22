using geoEvent.Model.Models;
using MathNet.Numerics.Statistics.Mcmc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class AdministrativeDivisionConfiguration : IEntityTypeConfiguration<AdministrativeDivision>
    {
        public void Configure(EntityTypeBuilder<AdministrativeDivision> builder)
        {
            builder.HasOne(d => d.Country)
                   .WithMany(d => d.Divisions)
                   .HasForeignKey(d => d.CountryId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(d => d.ParentDivision)
                   .WithMany(d => d.Children)
                   .HasForeignKey(d => d.ParentDivisionId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");
        }
    }
}