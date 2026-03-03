using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class SubGenre
    {
        [Key]
        public int SubGenreId { get; set; }
        public string Name { get; set; } = string.Empty;
        public int? GenreId { get; set; }
        public Genre? Genre { get; set; }
        public bool IsActive { get; set; } = true;
    }
}

