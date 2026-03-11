namespace UserService.Application.DTOs;

public class UserFilterDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? Role { get; set; }
    public bool? IsBanned { get; set; }
    public bool? IsVerified { get; set; }
    public string? Search { get; set; }
}