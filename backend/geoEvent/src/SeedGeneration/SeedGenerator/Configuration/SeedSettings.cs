using SeedGeneration.SeedGenerator.Configuration;

namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedSettings
{
    public List<SeedAdminOptions> SeedAdmins { get; set; } = new();
    public List<SeedUserOptions> SeedUsers { get; set; } = new();
    public List<SeedPreferenceOptions> SeedPreferences { get; set; } = new();
    public List<SeedReportOptions> SeedReports { get; set; } = new();
    public List<SeedSegmentOptions> SeedSegments { get; set; } = new();
    public List<SeedGenreOptions> SeedGenres { get; set; } = new();
    public List<SeedSubGenreOptions> SeedSubGenres { get; set; } = new();
    public List<SeedEventOptions> SeedEvents { get; set; } = new();
    public List<SeedEventImageOptions> SeedEventImages { get; set; } = new();
    public List<SeedEventLikeOptions> SeedEventLikes { get; set; } = new();
    public List<SeedBookmarkOptions> SeedBookmarks { get; set; } = new();
    public List<SeedCommentOptions> SeedComments { get; set; } = new();
    public List<SeedCommentLikeOptions> SeedCommentLikes { get; set; } = new();
    public List<SeedChatThreadOptions> SeedChatThreads { get; set; } = new();
    public List<SeedChatMessageOptions> SeedChatMessages { get; set; } = new();
    public List<SeedChatMessageLikeOptions> SeedChatMessageLikes { get; set; } = new();
    public List<SeedNotificationOptions> SeedNotifications { get; set; } = new();
    public List<SeedEventTicketOptions> SeedEventTickets { get; set; } = new();
    public List<SeedReservationOptions> SeedReservations { get; set; } = new();
    public List<SeedPaymentDetailOptions> SeedPaymentDetails { get; set; } = new();
    public List<SeedTicketOptions> SeedTickets { get; set; } = new();
}