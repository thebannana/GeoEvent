using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class CommentSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedCommentOptions> _comments;
    private readonly ILogger<CommentSeeder> _logger;

    public CommentSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<CommentSeeder> logger)
    {
        _dbContext = dbContext;
        _comments = options.Value.SeedComments ?? new List<SeedCommentOptions>();
        _logger = logger;
    }

    public string Name => "comments";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_comments.Count == 0)
        {
            _logger.LogWarning("No comments configured in SeedComments.");
            return;
        }

        foreach (var seed in _comments)
        {
            var eventExists = await _dbContext.Events.AnyAsync(e => e.EventId == seed.EventId, cancellationToken);
            if (!eventExists)
            {
                _logger.LogWarning("Skipping comment: EventId {EventId} does not exist.", seed.EventId);
                continue;
            }

            Comment? parent = null;
            if (seed.ParentCommentId.HasValue)
            {
                parent = await _dbContext.Comments
                    .FirstOrDefaultAsync(c => c.CommentId == seed.ParentCommentId.Value, cancellationToken);

                if (parent is null || parent.IsDeleted)
                {
                    _logger.LogWarning("Skipping comment: ParentCommentId {ParentId} does not exist or is deleted.", seed.ParentCommentId.Value);
                    continue;
                }
            }

            var comment = new Comment(
                seed.UserId,
                seed.EventId,
                seed.Content.Trim(),
                seed.ParentCommentId);

            await _dbContext.Comments.AddAsync(comment, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Comment created: CommentId {CommentId}, EventId {EventId}", comment.CommentId, comment.EventId);
        }
    }
}