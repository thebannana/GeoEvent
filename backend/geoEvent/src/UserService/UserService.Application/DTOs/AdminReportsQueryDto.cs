namespace UserService.Application.DTOs;

public class AdminReportsQueryDto
{
    public string? Status { get; set; }
    public string? TargetType { get; set; }
    public string? Search { get; set; }
    public string? SortBy { get; set; } = "createdAt";
    public bool Descending { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}