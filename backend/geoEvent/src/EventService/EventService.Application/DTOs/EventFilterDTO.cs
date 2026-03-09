namespace EventService.Application.DTOs;

public class EventFilterDto
{
    public int? CityId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? OrganizerId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public bool? IsOnline { get; set; }
    public bool? IsFeatured { get; set; }
    public string? SearchTerm { get; set; }
    public string? Status { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string SortBy { get; set; } = "StartDateTime";
    public bool SortDescending { get; set; } = false;
}
