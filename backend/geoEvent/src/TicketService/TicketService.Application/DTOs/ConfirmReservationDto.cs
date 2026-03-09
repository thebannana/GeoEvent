using System.ComponentModel.DataAnnotations;

namespace TicketService.Application.DTOs;

public class ConfirmReservationDto
{
    [Required]
    public string PaymentReference { get; set; } = string.Empty;
}
