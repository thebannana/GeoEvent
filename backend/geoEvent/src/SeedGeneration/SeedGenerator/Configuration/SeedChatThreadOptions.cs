namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedChatThreadOptions
{
    public string Type { get; set; } = "Direct";
    public string Title { get; set; } = string.Empty;
    public int? EventId { get; set; }
    public int? CreatedByUserId { get; set; }
    public List<int> ParticipantUserIds { get; set; } = new();
}