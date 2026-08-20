using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Domain.Entities;
using UserService.Domain.Enums;
using UserService.Infrastructure.Persistence;

namespace GeoEvent.SeedGenerator.Seeders;

public class ReportSeeder : ISeeder
{
    private readonly UserDbContext _dbContext;
    private readonly IReadOnlyList<SeedReportOptions> _reports;
    private readonly ILogger<ReportSeeder> _logger;

    public ReportSeeder(
        UserDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<ReportSeeder> logger)
    {
        _dbContext = dbContext;
        _reports = options.Value.SeedReports ?? new List<SeedReportOptions>();
        _logger = logger;
    }

    public string Name => "reports";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_reports.Count == 0)
        {
            _logger.LogWarning("No reports configured in SeedReports.");
            return;
        }

        foreach (var seedReport in _reports)
        {
            if (seedReport.ReporterId <= 0)
            {
                _logger.LogWarning("Skipping report: ReporterId must be > 0.");
                continue;
            }

            if (!Enum.TryParse<ReportTargetType>(seedReport.TargetType, true, out var targetType))
            {
                _logger.LogWarning("Skipping report: Invalid TargetType {TargetType}.", seedReport.TargetType);
                continue;
            }

            if (seedReport.TargetId <= 0)
            {
                _logger.LogWarning("Skipping report: TargetId must be > 0.");
                continue;
            }

            var reporterExists = await _dbContext.Users
                .AnyAsync(u => u.PersonId == seedReport.ReporterId, cancellationToken);

            if (!reporterExists)
            {
                _logger.LogWarning(
                    "Skipping report: ReporterId {ReporterId} does not exist.",
                    seedReport.ReporterId);
                continue;
            }

            if (targetType == ReportTargetType.User)
            {
                var targetUserExists = await _dbContext.Users
                    .AnyAsync(u => u.PersonId == seedReport.TargetId, cancellationToken);

                if (!targetUserExists)
                {
                    _logger.LogWarning(
                        "Skipping report: TargetType=User, TargetId {TargetId} does not exist.",
                        seedReport.TargetId);
                    continue;
                }
            }

            var report = new Report(
                targetType,
                seedReport.TargetId,
                seedReport.Reason,
                seedReport.ReporterId,
                seedReport.Description);

            if (!Enum.TryParse<ReportStatus>(seedReport.Status, true, out var status))
            {
                _logger.LogWarning(
                    "Report created with invalid status; defaulting to Pending.");
                status = ReportStatus.Pending;
            }

            if (status != ReportStatus.Pending)
            {
                if (!seedReport.ResolvedById.HasValue || seedReport.ResolvedById.Value <= 0)
                {
                    _logger.LogWarning(
                        "Skipping report: ResolvedById is required for non-Pending status.");
                    continue;
                }

                var resolverExists = await _dbContext.Users
                    .AnyAsync(u => u.PersonId == seedReport.ResolvedById.Value, cancellationToken);

                if (!resolverExists)
                {
                    _logger.LogWarning(
                        "Skipping report: ResolvedById {ResolvedById} does not exist.",
                        seedReport.ResolvedById.Value);
                    continue;
                }

                switch (status)
                {
                    case ReportStatus.UnderReview:
                        report.MarkUnderReview(
                            seedReport.ResolvedById.Value,
                            seedReport.ResolutionNote,
                            seedReport.ModeratorAction);
                        break;

                    case ReportStatus.Resolved:
                        report.Resolve(
                            seedReport.ResolvedById.Value,
                            seedReport.ResolutionNote,
                            seedReport.ModeratorAction);
                        break;

                    case ReportStatus.Dismissed:
                        report.Dismiss(
                            seedReport.ResolvedById.Value,
                            seedReport.ResolutionNote,
                            seedReport.ModeratorAction);
                        break;

                    default:
                        _logger.LogWarning(
                            "Unsupported report status {Status} for ReportId {ReportId}. Skipping status transition.",
                            status,
                            report.ReportId);
                        break;
                }
            }

            await _dbContext.Reports.AddAsync(report, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Report created: ReportId={ReportId}, TargetType={TargetType}, TargetId={TargetId}",
                report.ReportId,
                report.TargetType,
                report.TargetId);
        }
    }
}