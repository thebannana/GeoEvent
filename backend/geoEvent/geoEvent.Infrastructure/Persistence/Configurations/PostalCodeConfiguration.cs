using System.Reflection.Emit;
using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class PostalCodeConfiguration : IEntityTypeConfiguration<PostalCode>
    {
        public void Configure(EntityTypeBuilder<PostalCode> builder)
        {
            builder.HasKey(p => p.PostalCodeId);

            builder.HasOne(p => p.City)
                   .WithMany(c => c.PostalCodes)
                   .HasForeignKey(p => p.CityId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(p => p.Code).IsUnique();
            builder.HasIndex(p => p.CityId);

            builder.Property(p => p.Code).HasMaxLength(20).IsRequired();
            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");
        }
    }
}