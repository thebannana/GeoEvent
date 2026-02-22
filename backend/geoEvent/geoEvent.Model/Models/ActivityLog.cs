using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class ActivityLog
    {
        [Key]
        public int LogId { get; set; }
        public int TargetId { get; set; }
        public int SessionId { get; set; }
        public string ActionType { get; set; } = string.Empty;
        public string TargetType { get; set; } = string.Empty;
        public string Metadata { get; set; } = string.Empty;
        public int? UserId { get; set; }
        public User? User { get; set; }
        public int? CategoryId { get; set; }
        public Category? Category { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

