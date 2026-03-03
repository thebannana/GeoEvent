using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Segment
    {
        [Key]
        public int SegmentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? IconUrl { get; set; }
        public string? Color { get; set; }
        public bool IsActive { get; set; } = true;
        public ICollection<Genre> Genres { get; set; } = new List<Genre>();
    }
}

