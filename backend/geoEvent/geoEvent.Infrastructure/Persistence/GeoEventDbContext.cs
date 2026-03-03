using geoEvent.Model.Models;
using Microsoft.EntityFrameworkCore;

namespace geoEvent.Infrastructure.Persistence
{
    public class GeoEventDbContext : DbContext
    {
        public GeoEventDbContext(DbContextOptions<GeoEventDbContext> options)
            : base(options) { }

        public DbSet<Event> Events => Set<Event>();
        public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();
        public DbSet<AdministrativeDivision> AdministrativeDivisions => Set<AdministrativeDivision>();
        public DbSet<Bookmark> Bookmarks => Set<Bookmark>();
        public DbSet<City> Cities => Set<City>();
        public DbSet<Comment> Comments => Set<Comment>();
        public DbSet<Continent> Continents => Set<Continent>();
        public DbSet<Country> Countries => Set<Country>();
        public DbSet<EventImage> EventImages => Set<EventImage>();
        public DbSet<EventLike> EventLikes => Set<EventLike>();
        public DbSet<Message> Messages => Set<Message>();
        public DbSet<Notification> Notifications => Set<Notification>();
        public DbSet<NotificationQueue> NotificationQueues => Set<NotificationQueue>();
        public DbSet<PaymentDetail> PaymentDetails => Set<PaymentDetail>();
        public DbSet<Person> People => Set<Person>();
        public DbSet<PostalCode> PostalCodes => Set<PostalCode>();
        public DbSet<Report> Reports => Set<Report>();
        public DbSet<Reservation> Reservations => Set<Reservation>();
        public DbSet<User> Users => Set<User>();
        public DbSet<UserPreference> UserPreferences => Set<UserPreference>();
        public DbSet<Venue> Venues => Set<Venue>();
        public DbSet<Ticket> Tickets => Set<Ticket>();
        public DbSet<Segment> Segments => Set<Segment>();
        public DbSet<Genre> Genres => Set<Genre>();
        public DbSet<SubGenre> SubGenres => Set<SubGenre>();
        public DbSet<PriceZone> PriceZones => Set<PriceZone>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(GeoEventDbContext).Assembly);
        }
    }
}
