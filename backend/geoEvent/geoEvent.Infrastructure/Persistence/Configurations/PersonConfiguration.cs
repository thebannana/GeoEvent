using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class PersonConfiguration : IEntityTypeConfiguration<Person>
    {
        public void Configure(EntityTypeBuilder<Person> builder)
        {
            builder.HasKey(p => p.PersonId);

            builder.HasOne(p => p.City)
               .WithMany()
               .HasForeignKey(p => p.CityId)
               .OnDelete(DeleteBehavior.Restrict);

            builder.UseTptMappingStrategy();

            builder.HasIndex(p => p.CityId);
            builder.HasIndex(p => p.IsDeleted);

            builder.Property(p => p.FirstName).HasMaxLength(100).IsRequired();
            builder.Property(p => p.LastName).HasMaxLength(100).IsRequired();
            builder.Property(p => p.PhoneNumber).HasMaxLength(20);
            builder.Property(p => p.ImageUrl).HasMaxLength(500);
        }
    }
}