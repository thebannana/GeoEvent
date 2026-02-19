using System;
using System.Collections.Generic;
using System.Text;
using geoEvent.Model.Models;
using System.Threading;
using System.Threading.Tasks;

namespace geoEvent.Services.Interfaces { 
    public interface IEventRepository
    {
        Task<Event?> GetByIdAsync(int id, CancellationToken ct = default);
        Task AddAsync(Event entity, CancellationToken ct = default);
    }
}


