namespace TicketService.Application.DTOs;

public sealed class UpdateDefaultEventTicketRequest
{
    public decimal Price { get; set; }
    public int Capacity { get; set; }
}
