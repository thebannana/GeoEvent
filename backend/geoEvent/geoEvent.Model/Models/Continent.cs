using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.Metrics;

namespace geoEvent.Model.Models
{
    public class Continent
    {
        [Key]
        public int ContinentId { get; set; }
        public string ContinentName { get; set; } = string.Empty;
        [MaxLength(10)]
        public string ContinentCode { get; set; } = string.Empty;
    }
}

