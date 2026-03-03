using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Venue
    {
        [Key]
        public int VenueId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Address { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public int? CityId { get; set; }
        public City? City { get; set; }
        public string? VenueType { get; set; }
        public string? WebsiteUrl { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Description { get; set; }
        public bool IsVerified { get; set; } = false;
        public DateTime CreatedAt { get; set; }
        public string? TimeZone { get; set; }
        public string? Locale { get; set; }
        public ICollection<Event> Events { get; set; } = new List<Event>();
        public ICollection<PriceZone> PriceZones { get; set; } = new List<PriceZone>();
    }
}

