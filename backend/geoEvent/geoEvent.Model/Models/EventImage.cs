using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class EventImage
    {
        [Key]
        public int ImageId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; }
        public bool IsCover { get; set; }
        public int? EventId { get; set; }
        public Event? Event { get; set; }
    }
}

