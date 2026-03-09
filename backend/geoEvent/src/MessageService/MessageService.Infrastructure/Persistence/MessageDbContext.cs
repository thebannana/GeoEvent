using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MessageService.Infrastructure.Persistence;

public class MessageDbContext : DbContext
{
    public MessageDbContext(DbContextOptions<MessageDbContext> options) : base(options) { }

    public DbSet<Message> Messages => Set<Message>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MessageDbContext).Assembly);
    }
}
