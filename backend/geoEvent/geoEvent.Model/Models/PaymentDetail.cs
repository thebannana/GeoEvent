using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class PaymentDetail
    {
        [Key]
        public int PaymentId { get; set; }
        public DateTime PaidAt { get; set; }
        public int? ReservationId { get; set; }
        public Reservation? Reservation { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public double Amount { get; set; }
        public string? TransactionId { get; set; }
        public string? Currency { get; set; } = "EUR";
    }
}

