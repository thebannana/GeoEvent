using MessageService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MessageService.Infrastructure.Persistence.Configurations;

public class ChatThreadParticipantConfiguration : IEntityTypeConfiguration<ChatThreadParticipant>
{
    public void Configure(EntityTypeBuilder<ChatThreadParticipant> builder)
    {
        builder.ToTable("ChatThreadParticipants");

        builder.HasKey(x => new { x.ThreadId, x.UserId });
    }
}