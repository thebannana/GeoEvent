using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class UserPreference
    {
        [Key]
        public int PrefId { get; set; }
        public DateTime LastUpdated { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
        public int? SegmentId { get; set; }
        public Segment? Segment { get; set; }
        public int? GenreId { get; set; }
        public Genre? Genre { get; set; }
        public double Score { get; set; }
    }
}

