using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Reservation
    {
        [Key]
        public int ReservationId { get; set; }
        public DateTime ReservedAt { get; set; }
        public int? EventId { get; set; }
        public Event? Event { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
        public int? TicketId { get; set; }
        public Ticket? Ticket { get; set; }
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
    }
}

