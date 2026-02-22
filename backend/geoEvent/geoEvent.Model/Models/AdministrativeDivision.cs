using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.Metrics;

namespace geoEvent.Model.Models
{
    public class AdministrativeDivision
    {
        [Key]
        public int DivisionId { get; set; }
        public int? CountryId { get; set; }
        public Country? Country { get; set; }
        public int? ParentDivisionId { get; set; }
        public AdministrativeDivision? ParentDivision { get; set; }
        public ICollection<AdministrativeDivision>? Children { get; set; } = new List<AdministrativeDivision>();
        public string DivisionName { get; set; } = string.Empty;
        [MaxLength(20)]
        public string DivisionCode { get; set; } = string.Empty;
        [MaxLength(50)]
        public string DivisionType { get; set; } = string.Empty;
        public int Level { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public bool IsActive { get; set; }

    }
}

