using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class City
    {
        [Key]
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        public string NormalizedName {  get; set; } = string.Empty;
        public decimal Longitude { get; set; }
        public decimal Latitude { get; set; }
        public int? DivisionId { get; set; }
        public AdministrativeDivision? Division { get; set; }
        public ICollection<PostalCode>? PostalCodes { get; set; } = new List<PostalCode>();
        public bool IsActive { get; set; }
    }
}

