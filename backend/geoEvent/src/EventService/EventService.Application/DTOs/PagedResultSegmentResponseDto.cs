namespace EventService.Application.DTOs;
public class PagedResultSegmentResponseDto
{
    public List<SegmentResponseDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
