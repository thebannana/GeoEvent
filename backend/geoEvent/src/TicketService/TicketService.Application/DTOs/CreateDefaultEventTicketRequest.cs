namespace TicketService.Application.DTOs;

public sealed class CreateDefaultEventTicketRequest
{
    public int EventId { get; set; }
    public decimal Price { get; set; }
    public int Capacity { get; set; }
    public DateTime StartDateTime { get; set; }
}