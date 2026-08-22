using EventService.Domain.Enums;

public class EventFilterDto
{
    public int? OrganizerId { get; set; }
    public EventStatus? Status { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public bool? IsFeatured { get; set; }
    public bool? CanViewReservations { get; set; }
    public string? SearchTerm { get; set; }
    public string? SortBy { get; set; } = "StartDateTime";
    public bool SortDescending { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public bool UsePreferences { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}