using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EventService.Application.DTOs;

public class LikedEventResponseDto
{
    public int EventId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public DateTime LikedAt { get; set; }
    public bool IsLiked { get; set; } = true;
}
