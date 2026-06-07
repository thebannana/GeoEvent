using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MessageService.Infrastructure.Persistence;

public class MessageDbContext : DbContext
{
    public MessageDbContext(DbContextOptions<MessageDbContext> options) : base(options) { }

    public DbSet<Message> Messages => Set<Message>();
    public DbSet<ChatThread> ChatThreads => Set<ChatThread>();
    public DbSet<ChatThreadParticipant> ChatThreadParticipants => Set<ChatThreadParticipant>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<ChatMessageLike> ChatMessageLikes => Set<ChatMessageLike>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MessageDbContext).Assembly);
    }
}
