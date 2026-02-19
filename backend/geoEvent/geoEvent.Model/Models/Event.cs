using System;
using System.Collections.Generic;
using System.Text;

namespace geoEvent.Model.Models
{
    public class Event
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

