using geoEvent.Model.Models;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System;

public class Event
{
    [Key]
    public int EventId { get; set; }
    public int? OrganizerId { get; set; }
    public User? Organizer { get; set; }
    public int? SegmentId { get; set; }
    public Segment? Segment { get; set; }
    public int? GenreId { get; set; }
    public Genre? Genre { get; set; }
    public int? SubGenreId { get; set; }
    public SubGenre? SubGenre { get; set; }
    public string? PromoterName { get; set; } = string.Empty;
    public string? Locale { get; set; } = "bs-BA";
    public int? VenueId { get; set; }
    public Venue? Venue { get; set; }
    public int? CityId { get; set; }
    public City? City { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Longitude { get; set; }
    public decimal Latitude { get; set; }
    public DateTime StartDateTime { get; set; }
    public DateTime EndDateTime { get; set; }
    public int Capacity { get; set; } = 0;
    public decimal Price { get; set; } = 0;
    [MaxLength(50)]
    public string Status { get; set; } = string.Empty;
    public bool IsOnline { get; set; } = false;
    public bool IsFeatured { get; set; } = false;
    public int ViewCount { get; set; } = 0;
    public int LikesCount { get; set; } = 0;
    public string? Tags { get; set; }
    public string? ExternalUrl { get; set; }
    public string? ExternalSource { get; set; }
    public string? ExternalId { get; set; }
    public string? AccessibilityInfo { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
    public ICollection<EventImage> Images { get; set; } = new List<EventImage>();
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
    public ICollection<EventLike> Likes { get; set; } = new List<EventLike>();
    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
