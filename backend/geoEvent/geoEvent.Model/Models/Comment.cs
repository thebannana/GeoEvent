using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class Comment
    {
        [Key]
        public int CommentId { get; set; }
        public string Content { get; set; } = string.Empty;
        public int LikesCount { get; set; }
        public int? UserId { get; set; }
        public User? User { get; set; }
        public int? EventId { get; set; }
        public Event? Event { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

