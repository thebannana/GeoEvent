using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Event
    {
        [Key]
        public int EventId { get; set; }
        public int? OrganizerId { get; set; }
        public User? Organizer { get; set; }
        public int? CategoryId { get; set; }
        public Category? Category { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Longitude { get; set; }
        public decimal Latitude { get; set; }
        public DateTime StartDateTime { get; set; }
        public DateTime EndDateTime { get; set; }
        public int Capacity { get; set; }
        public double Price { get; set; }
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
    }
}

