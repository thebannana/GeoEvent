namespace UserService.Application.DTOs;
public sealed class ExternalEventLookupDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? OrganizerDisplayName { get; set; }
}
