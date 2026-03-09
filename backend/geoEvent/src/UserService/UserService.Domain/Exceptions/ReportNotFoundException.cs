namespace UserService.Domain.Exceptions;

public class ReportNotFoundException : Exception
{
    public ReportNotFoundException(int reportId)
        : base($"Report with ID {reportId} was not found.") { }
}
