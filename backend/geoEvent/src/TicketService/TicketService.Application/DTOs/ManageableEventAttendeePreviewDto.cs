namespace TicketService.Application.DTOs;

public sealed class ManageableEventAttendeePreviewDto
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int Quantity { get; set; }
}