using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace geoEvent.Model.Models
{
    public class RefreshToken
    {
        [Key]
        public int TokenId { get; set; }
        public string TokenHash { get; set; } = string.Empty;
        public int? UserId { get; set; }
        public User? User { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ExpiresAt { get; set; }
        public DateTime? RevokedAt { get; set; }
        public string? DeviceInfo { get; set; }
        public string? IpAddress { get; set; }
        public bool IsRevoked => RevokedAt.HasValue || DateTime.UtcNow > ExpiresAt;
    }
}

