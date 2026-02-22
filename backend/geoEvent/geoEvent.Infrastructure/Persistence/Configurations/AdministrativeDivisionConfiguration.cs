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
            builder.HasKey(d => d.DivisionId);

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

            builder.HasIndex(d => d.CountryId);
            builder.HasIndex(d => d.ParentDivisionId);
            builder.HasIndex(d => d.DivisionCode);
            builder.HasIndex(d => new { d.Level, d.DivisionType });

            builder.Property(d => d.DivisionName).HasMaxLength(200).IsRequired();
            builder.Property(d => d.DivisionCode).HasMaxLength(20);
            builder.Property(d => d.DivisionType).HasMaxLength(50).IsRequired();
        }
    }
}