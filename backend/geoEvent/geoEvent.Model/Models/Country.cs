using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.Metrics;

namespace geoEvent.Model.Models
{
    public class Country
    {
        [Key]
        public int CountryId { get; set; }
        public string CountryName { get; set; } = string.Empty;
        [MaxLength(2)]
        public string CountryCodeAlpha2 { get; set; } = string.Empty;
        [MaxLength(3)]
        public string CountryCodeAlpha3 { get; set; } = string.Empty;
        public int CountryCodeNumeric { get; set; }
        public bool IsActive { get; set; } = true;
        public int? ContinentId { get; set; }
        public Continent? Continent { get; set; }
        public ICollection<AdministrativeDivision>? Divisions { get; set; } = new List<AdministrativeDivision>();

    }
}

