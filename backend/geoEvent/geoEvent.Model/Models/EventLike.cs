using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class EventLike
    {
        [Key]
        public int LikeId { get; set; }
        public DateTime LikedAt { get; set; }
        public int? EventId { get; set; }
        public Event? Event { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }

    }
}

