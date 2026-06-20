namespace GeoEvent.HelperWorkers.Options;

public class NotificationServiceOptions
{
    public const string SectionName = "Services:NotificationService";

    public string BaseUrl { get; set; } = string.Empty;
    public string InternalApiKey { get; set; } = string.Empty;
}