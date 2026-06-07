public class PublicEventReservationSummaryDto
{
    public int EventId { get; set; }
    public int Capacity { get; set; }
    public int ReservedCount { get; set; }
    public int ConfirmedCount { get; set; }
    public int RemainingSpots { get; set; }
}