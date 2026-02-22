using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class CategoryConfiguration : IEntityTypeConfiguration<Category>
    {
        public void Configure(EntityTypeBuilder<Category> builder)
        {
            builder.HasKey(c => c.CategoryId);

            builder.HasIndex(c => c.CategoryName);

            builder.Property(c => c.CategoryName).HasMaxLength(100).IsRequired();
            builder.Property(c => c.Color).HasMaxLength(7).IsRequired();
            builder.Property(c => c.IconUrl).HasMaxLength(500).IsRequired();
            builder.Property(c => c.Description).HasMaxLength(500);
        }
    }
}