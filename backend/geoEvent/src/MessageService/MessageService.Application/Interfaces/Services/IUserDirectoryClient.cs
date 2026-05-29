using MessageService.Application.DTOs;

namespace MessageService.Application.Interfaces.Services;

public interface IUserDirectoryClient
{
    Task<PublicUserSummaryDto?> GetPublicUserAsync(int userId, CancellationToken cancellationToken = default);
    Task<Dictionary<int, PublicUserSummaryDto>> GetPublicUsersAsync(IEnumerable<int> userIds, CancellationToken cancellationToken = default);
}