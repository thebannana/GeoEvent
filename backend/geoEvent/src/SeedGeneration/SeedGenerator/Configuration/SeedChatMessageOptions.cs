namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedChatMessageOptions
{
    public long ThreadId { get; set; }
    public int SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public long? ReplyToMessageId { get; set; }
}