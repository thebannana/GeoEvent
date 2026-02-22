using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Message
    {
        [Key]
        public int MessageId { get; set; }
        public string Content { get; set; } = string.Empty;
        public int LikesCount { get; set; }
        public int? SenderId { get; set; }
        public User? Sender { get; set; }
        public int? ReceiverId { get; set; }
        public User? Receiver { get; set; }
        public int? EventId { get; set; }
        public Event? Event { get; set; }
        public bool IsRead { get; set; }
        public DateTime SentAt { get; set; }
    }
}

