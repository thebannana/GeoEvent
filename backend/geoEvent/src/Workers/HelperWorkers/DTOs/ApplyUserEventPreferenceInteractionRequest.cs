namespace GeoEvent.HelperWorkers.DTOs;

public sealed class ApplyUserEventPreferenceInteractionRequest
{
    public int UserId { get; set; }
    public int EventId { get; set; }
    public int? SegmentId { get; set; }
    public int? GenreId { get; set; }
    public int? SubGenreId { get; set; }
    public string InteractionType { get; set; } = string.Empty;
    public DateTime OccurredAt { get; set; }
}