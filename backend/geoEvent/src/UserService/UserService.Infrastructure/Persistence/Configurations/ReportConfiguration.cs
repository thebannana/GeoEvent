using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Persistence.Configurations;

public class ReportConfiguration : IEntityTypeConfiguration<Report>
{
    public void Configure(EntityTypeBuilder<Report> builder)
    {
        builder.HasKey(r => r.ReportId);

        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.TargetType)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.Reason)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(r => r.Description)
            .HasMaxLength(2000);

        builder.HasOne(r => r.Reporter)
            .WithMany(u => u.FiledReports)
            .HasForeignKey(r => r.ReporterId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.HasOne(r => r.ResolvedBy)
            .WithMany(u => u.ResolvedReports)
            .HasForeignKey(r => r.ResolvedById)
            .OnDelete(DeleteBehavior.NoAction);

        builder.HasIndex(r => r.Status);
        builder.HasIndex(r => r.ReporterId);
        builder.HasIndex(r => r.ResolvedById);
        builder.HasIndex(r => new { r.TargetType, r.TargetId });
        builder.Property(r => r.CreatedAt).IsRequired();
        builder.Property(r => r.ResolvedAt);
        builder.HasIndex(r => r.CreatedAt);

    }
}
