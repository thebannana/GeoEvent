public interface IUserDirectoryService
{
    Task<List<PublicUserProfileDto>> GetPublicProfilesAsync(IEnumerable<int> userIds);
}