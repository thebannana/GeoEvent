using System.ComponentModel.DataAnnotations;

namespace TicketService.Application.DTOs;

public class CreateReservationDto
{
    [Required]
    public int EventId { get; set; }

    [Required]
    public int EventTicketId { get; set; }

    [Required]
    [Range(1, 10)]
    public int Quantity { get; set; } = 1;

    public string Currency { get; set; } = "BAM";
    public string? SeatNumber { get; set; }
    public string? Section { get; set; }
    public string? Notes { get; set; }
}
