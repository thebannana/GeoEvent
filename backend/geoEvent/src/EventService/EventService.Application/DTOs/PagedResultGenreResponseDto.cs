namespace EventService.Application.DTOs;
public class PagedResultGenreResponseDto
{
    public List<GenreResponseDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
