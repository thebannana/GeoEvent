using System.ComponentModel.DataAnnotations;
using TicketService.Domain.Enums;

namespace TicketService.Application.DTOs;

public class ConfirmReservationDto
{
    [Required]
    public string PaymentReference { get; set; } = string.Empty;

    [Required]
    public PaymentMethod PaymentMethod { get; set; }

    public string Currency { get; set; } = "BAM";

    public string? ProviderPaymentId { get; set; }

    public string? ProviderOrderId { get; set; }
}