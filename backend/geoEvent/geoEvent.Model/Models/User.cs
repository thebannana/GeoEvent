using System;
using System.ComponentModel.DataAnnotations;

namespace geoEvent.Model.Models
{
    public class User:Person
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public byte[] PasswordHash { get; set; } = Array.Empty<byte>();
        public byte[] PasswordSalt { get; set; } = Array.Empty<byte>();
        public string Role { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public bool IsBanned { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ConsentGivenAt { get; set; }
        public string? ConsentVersion { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public string? LastLoginIp { get; set; }
        public int FailedLoginAttempts { get; set; } = 0;
        public DateTime? LockoutUntil { get; set; }
    }
}

