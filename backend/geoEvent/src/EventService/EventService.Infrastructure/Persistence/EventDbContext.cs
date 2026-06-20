using EventService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EventService.Infrastructure.Persistence;

public class EventDbContext : DbContext
{
    public EventDbContext(DbContextOptions<EventDbContext> options) : base(options)
    {
    }

    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventImage> EventImages => Set<EventImage>();
    public DbSet<EventLike> EventLikes => Set<EventLike>();
    public DbSet<Segment> Segments => Set<Segment>();
    public DbSet<Genre> Genres => Set<Genre>();
    public DbSet<SubGenre> SubGenres => Set<SubGenre>();
    public DbSet<Bookmark> Bookmarks => Set<Bookmark>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<CommentLike> CommentLikes => Set<CommentLike>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(EventDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}