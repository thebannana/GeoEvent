namespace TicketService.Domain.Entities;

public class ProcessedWebhookEvent
{
    public int ProcessedWebhookEventId { get; set; }
    public string Provider { get; set; } = string.Empty;
    public string EventId { get; set; } = string.Empty;
    public DateTime ProcessedAt { get; set; } = DateTime.UtcNow;
}