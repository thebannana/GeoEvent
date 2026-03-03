using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public abstract class Person
    {
        [Key]
        public int PersonId { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public DateTime BirthDate { get; set; }
        public string LastName { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public int? CityId { get; set; }
        public City? City { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
        public DateTime? DeletedAt { get; set; }
    }
}

