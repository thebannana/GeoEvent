namespace GeoEvent.HelperWorkers.Interfaces;

public interface IMessageChatAdminClient
{
    Task AddUserToEventThreadAsync(int eventId, int userId, int? addedByUserId = null);
    Task RemoveUserFromEventThreadAsync(int eventId, int userId);
    Task HandleDeletedUserAsync(int userId);
}