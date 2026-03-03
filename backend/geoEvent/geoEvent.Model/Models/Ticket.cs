using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Ticket
    {
        [Key]
        public int TicketId { get; set; }
        public int EventId { get; set; }
        public Event? Event { get; set; }
        public string TicketType { get; set; } = string.Empty;
        public decimal Price { get; set; } = 0;
        public int TotalQuantity { get; set; } = 0;
        public int SoldQuantity { get; set; } = 0;
        public DateTime? SaleStartDate { get; set; }
        public DateTime? SaleEndDate { get; set; }
        public bool IsActive { get; set; } = true;
        public string? Description { get; set; }
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public int? PriceZoneId { get; set; }
        public PriceZone? PriceZone { get; set; }

    }
}

