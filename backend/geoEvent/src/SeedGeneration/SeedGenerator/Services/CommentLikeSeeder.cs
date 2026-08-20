using EventService.Domain.Entities;
using EventService.Infrastructure.Persistence;
using MassTransit.Contracts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;

namespace GeoEvent.SeedGenerator.Seeders;

public class CommentLikeSeeder : ISeeder
{
    private readonly EventDbContext _dbContext;
    private readonly IReadOnlyList<SeedCommentLikeOptions> _likes;
    private readonly ILogger<CommentLikeSeeder> _logger;

    public CommentLikeSeeder(
        EventDbContext dbContext,
        IOptions<SeedSettings> options,
        ILogger<CommentLikeSeeder> logger)
    {
        _dbContext = dbContext;
        _likes = options.Value.SeedCommentLikes ?? new List<SeedCommentLikeOptions>();
        _logger = logger;
    }

    public string Name => "commentlikes";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_likes.Count == 0)
        {
            _logger.LogWarning("No comment likes configured in SeedCommentLikes.");
            return;
        }

        foreach (var seed in _likes)
        {
            var commentExists = await _dbContext.Comments.AnyAsync(c => c.CommentId == seed.CommentId, cancellationToken);
            if (!commentExists)
            {
                _logger.LogWarning("Skipping comment like: CommentId {CommentId} does not exist.", seed.CommentId);
                continue;
            }

            var existing = await _dbContext.CommentLikes
                .FirstOrDefaultAsync(l => l.CommentId == seed.CommentId && l.UserId == seed.UserId, cancellationToken);

            if (existing is not null)
            {
                _logger.LogInformation("Comment like already exists: CommentId {CommentId}, UserId {UserId}", seed.CommentId, seed.UserId);
                continue;
            }

            var like = new CommentLike(seed.CommentId, seed.UserId);

            await _dbContext.CommentLikes.AddAsync(like, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Comment like created: CommentId {CommentId}, UserId {UserId}", like.CommentId, like.UserId);
        }
    }
}