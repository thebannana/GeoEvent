using UserService.Application.DTOs;

namespace UserService.Application.Interfaces.Services;

public interface IExternalValidationService
{
    Task<bool> EventExistsAsync(int eventId);
    Task<bool> CommentExistsAsync(int commentId);
    Task<bool> ReviewExistsAsync(int reviewId);

    Task<ExternalEventLookupDto?> GetEventLookupAsync(int eventId);
    Task<ExternalCommentLookupDto?> GetCommentLookupAsync(int commentId);
    Task<ExternalReviewLookupDto?> GetReviewLookupAsync(int reviewId);
}