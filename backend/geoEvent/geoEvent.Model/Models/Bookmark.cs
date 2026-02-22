using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Bookmark
    {
        [Key]
        public int BookmarkId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public DateTime SavedAt { get; set; }
        public string Memo { get; set; } = string.Empty;
        public int? EventId { get; set; }
        public Event? Event { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
    }
}

