using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Persistence.Configurations;

public class UserRatingConfiguration : IEntityTypeConfiguration<UserRating>
{
    public void Configure(EntityTypeBuilder<UserRating> builder)
    {
        builder.ToTable("UserRatings");

        builder.HasKey(x => x.RatingId);

        builder.Property(x => x.Value)
            .IsRequired();

        builder.Property(x => x.Comment)
            .HasMaxLength(1000)
            .IsRequired(false);

        builder.HasIndex(x => new { x.RaterId, x.RatedUserId })
            .IsUnique();

        builder.HasOne(x => x.Rater)
            .WithMany()
            .HasForeignKey(x => x.RaterId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.HasOne(x => x.RatedUser)
            .WithMany()
            .HasForeignKey(x => x.RatedUserId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.ToTable(t => t.HasCheckConstraint("CK_UserRating_Value", "[Value] >= 1 AND [Value] <= 5"));

        builder.HasQueryFilter(x =>
            (x.Rater == null || !x.Rater.Person!.IsDeleted) &&
            (x.RatedUser == null || !x.RatedUser.Person!.IsDeleted));
    }
}