using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace geoEvent.Infrastructure.Persistence.Configurations
{
    public class SubGenreConfiguration : IEntityTypeConfiguration<SubGenre>
    {
        public void Configure(EntityTypeBuilder<SubGenre> builder)
        {
            builder.HasKey(sg => sg.SubGenreId);

            builder.HasOne(sg => sg.Genre)
                   .WithMany(g => g.SubGenres)
                   .HasForeignKey(sg => sg.GenreId)
                   .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(sg => sg.Name);
            builder.HasIndex(sg => sg.GenreId);
            builder.HasIndex(sg => sg.IsActive);
            builder.HasIndex(sg => new { sg.GenreId, sg.IsActive });

            builder.Property(sg => sg.Name).HasMaxLength(100).IsRequired();
            builder.Property(sg => sg.IsActive).HasDefaultValue(true);
        }
    }

}