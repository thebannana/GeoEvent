namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedCommentOptions
{
    public int UserId { get; set; }
    public int EventId { get; set; }
    public int? ParentCommentId { get; set; }
    public string Content { get; set; } = "Comment";
}