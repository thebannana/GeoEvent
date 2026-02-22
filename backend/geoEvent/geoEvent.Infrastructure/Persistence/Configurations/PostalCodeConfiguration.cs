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
            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");
        }
    }
}