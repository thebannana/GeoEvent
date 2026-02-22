using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class ReportConfiguration : IEntityTypeConfiguration<Report>
    {
        public void Configure(EntityTypeBuilder<Report> builder)
        {
            builder.HasKey(r => r.ReportId);

            builder.HasOne(r => r.Reporter)
                   .WithMany()
                   .HasForeignKey(r => r.ReporterId)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasOne(r => r.ResolvedBy)
                   .WithMany()
                   .HasForeignKey(r => r.ResolvedById)
                   .OnDelete(DeleteBehavior.NoAction);

            builder.HasIndex(r => r.ReporterId);
            builder.HasIndex(r => r.ResolvedById);
            builder.HasIndex(r => r.Status);
            builder.HasIndex(r => new { r.TargetType, r.TargetId });

            builder.Property(r => r.TargetType).HasMaxLength(50).IsRequired();
            builder.Property(r => r.Reason).HasMaxLength(200).IsRequired();
            builder.Property(r => r.Status).HasMaxLength(50).IsRequired();
            builder.Property(r => r.Description).HasMaxLength(2000);
        }
    }
}