using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class PostalCode
    {
        [Key]
        public int PostalCodeId { get; set; }
        public string Code { get; set; } = string.Empty;
        public decimal Longitude { get; set; }
        public decimal Latitude { get; set; }
        public int? CityId { get; set; }
        public City? City { get; set; }

    }
}

