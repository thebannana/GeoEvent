using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class NotificationQueue
    {
        [Key]
        public int QueueId { get; set; }
        public DateTime ScheduledAt { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;
        public int AttemptCount { get; set; }
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string payload { get; set; } = string.Empty;
    }
}

