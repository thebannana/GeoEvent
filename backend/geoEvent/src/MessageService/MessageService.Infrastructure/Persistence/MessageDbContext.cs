using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

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
        base.OnModelCreating(modelBuilder);

        var utcDateTimeConverter = new ValueConverter<DateTime, DateTime>(
            v => v.Kind == DateTimeKind.Utc ? v : v.ToUniversalTime(),
            v => v.Kind == DateTimeKind.Utc
                ? v
                : DateTime.SpecifyKind(v, DateTimeKind.Utc)
        );

        var utcNullableDateTimeConverter = new ValueConverter<DateTime?, DateTime?>(
            v => !v.HasValue
                ? v
                : (v.Value.Kind == DateTimeKind.Utc
                    ? v.Value
                    : v.Value.ToUniversalTime()),
            v => !v.HasValue
                ? v
                : (v.Value.Kind == DateTimeKind.Utc
                    ? v.Value
                    : DateTime.SpecifyKind(v.Value, DateTimeKind.Utc))
        );

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                if (property.ClrType == typeof(DateTime))
                {
                    property.SetValueConverter(utcDateTimeConverter);
                }
                else if (property.ClrType == typeof(DateTime?))
                {
                    property.SetValueConverter(utcNullableDateTimeConverter);
                }
            }
        }

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MessageDbContext).Assembly);
    }
}