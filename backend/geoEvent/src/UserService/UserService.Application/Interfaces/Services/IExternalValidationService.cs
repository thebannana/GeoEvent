namespace UserService.Application.Interfaces.Services;

public interface IExternalValidationService
{
    Task<bool> EventExistsAsync(int eventId);
    Task<bool> CommentExistsAsync(int commentId);
    Task<bool> ReviewExistsAsync(int reviewId);
}