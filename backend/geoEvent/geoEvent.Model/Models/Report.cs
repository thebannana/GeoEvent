using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Report
    {
        [Key]
        public int ReportId { get; set; }
        public string TargetType { get; set; } = string.Empty;
        public int? TargetId { get; set; }
        public string Reason { get; set; } = string.Empty;
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
        public int? ReporterId { get; set; }
        public User? Reporter { get; set; }
        public int? ResolvedById { get; set; }
        public User? ResolvedBy { get; set; }
        public string Description { get; set; } = string.Empty;
    }
}

