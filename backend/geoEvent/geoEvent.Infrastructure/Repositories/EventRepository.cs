using geoEvent.Model.Models;
using geoEvent.Services.Interfaces;
using geoEvent.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace geoEvent.Infrastructure.Repositories
{
    public class EventRepository : IEventRepository
    {
        private readonly GeoEventDbContext _db;

        public EventRepository(GeoEventDbContext db) => _db = db;

        public Task<Event?> GetByIdAsync(int id, CancellationToken ct = default)
            => _db.Events.FirstOrDefaultAsync(e => e.EventId == id, ct);

        public async Task AddAsync(Event entity, CancellationToken ct = default)
        {
            await _db.Events.AddAsync(entity, ct);
            await _db.SaveChangesAsync(ct);
        }
    }
}
