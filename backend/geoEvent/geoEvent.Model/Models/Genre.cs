using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Genre
    {
        [Key]
        public int GenreId { get; set; }
        public string Name { get; set; } = string.Empty;
        public int? SegmentId { get; set; }
        public Segment? Segment { get; set; }
        public bool IsActive { get; set; } = true;
        public ICollection<SubGenre> SubGenres { get; set; } = new List<SubGenre>();
    }
}

