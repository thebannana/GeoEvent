namespace EventService.Application.Common.Settings;

public class SupabaseStorageSettings
{
    public const string SectionName = "SupabaseStorage";

    public string Url { get; set; } = string.Empty;
    public string ServiceRoleKey { get; set; } = string.Empty;
    public string Bucket { get; set; } = "event-images";
    public string Folder { get; set; } = "events";
}