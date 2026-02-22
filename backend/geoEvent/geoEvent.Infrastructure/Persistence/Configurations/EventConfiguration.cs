using geoEvent.Model.Models;
using MathNet.Numerics.Statistics.Mcmc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class EventConfiguration : IEntityTypeConfiguration<Event>
    {
        public void Configure(EntityTypeBuilder<Event> builder)
        {
            builder.HasKey(e => e.EventId);

            builder.HasOne(e => e.Organizer)
                   .WithMany()
                   .HasForeignKey(e => e.OrganizerId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(e => e.Category)
                   .WithMany()
                   .HasForeignKey(e => e.CategoryId)
                   .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(e => e.OrganizerId);
            builder.HasIndex(e => e.CategoryId);
            builder.HasIndex(e => e.StartDateTime);
            builder.HasIndex(e => e.Status);
            builder.HasIndex(e => new { e.Longitude, e.Latitude });

            builder.Property(e => e.Title).HasMaxLength(200).IsRequired();
            builder.Property(e => e.Description).HasMaxLength(2000);
            builder.Property(e => e.Status).HasMaxLength(50).IsRequired();
            builder.Property(e => e.Latitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Longitude).HasColumnType("decimal(9,6)");
            builder.Property(e => e.Price).HasColumnType("decimal(18,2)");
        }
    }
}