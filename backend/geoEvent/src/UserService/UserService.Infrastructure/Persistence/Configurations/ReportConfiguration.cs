using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;
using UserService.Domain.Enums;

namespace UserService.Infrastructure.Persistence.Configurations;

public class ReportConfiguration : IEntityTypeConfiguration<Report>
{
    public void Configure(EntityTypeBuilder<Report> builder)
    {
        builder.ToTable("Reports", table =>
        {
            table.HasCheckConstraint(
                "CK_Report_TargetId_Positive",
                "[TargetId] > 0");

            table.HasCheckConstraint(
                "CK_Report_Status_Valid",
                $"[Status] IN ('{ReportStatus.Pending}', '{ReportStatus.UnderReview}', '{ReportStatus.Resolved}', '{ReportStatus.Dismissed}')");

            table.HasCheckConstraint(
                "CK_Report_TargetType_Valid",
                $"[TargetType] IN ('{ReportTargetType.User}', '{ReportTargetType.Event}', '{ReportTargetType.Comment}')");
        });

        builder.HasKey(r => r.ReportId);

        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.TargetType)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.TargetId)
            .IsRequired();

        builder.Property(r => r.Reason)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(r => r.Description)
            .HasMaxLength(2000)
            .IsRequired(false);

        builder.Property(r => r.ResolutionNote)
            .HasMaxLength(4000)
            .IsRequired(false);

        builder.Property(r => r.ModeratorAction)
            .HasMaxLength(4000)
            .IsRequired(false);

        builder.Property(r => r.CreatedAt)
            .IsRequired();

        builder.Property(r => r.ResolvedAt)
            .IsRequired(false);

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
        builder.HasIndex(r => r.CreatedAt);
        builder.HasIndex(r => new { r.Status, r.CreatedAt });
        builder.HasIndex(r => new { r.ReporterId, r.TargetType, r.TargetId, r.Status });

        builder.HasQueryFilter(r =>
            (r.Reporter == null || !r.Reporter.Person!.IsDeleted) &&
            (r.ResolvedBy == null || !r.ResolvedBy.Person!.IsDeleted));
    }
}