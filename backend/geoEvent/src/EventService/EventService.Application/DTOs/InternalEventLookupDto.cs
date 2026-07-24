namespace EventService.Application.DTOs;
public sealed class InternalEventLookupDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? OrganizerDisplayName { get; set; }
}
