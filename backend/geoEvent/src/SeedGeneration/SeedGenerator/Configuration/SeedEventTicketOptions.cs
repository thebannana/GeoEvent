namespace SeedGeneration.SeedGenerator.Configuration;

public class SeedEventTicketOptions
{
    public int EventId { get; set; }
    public string TicketType { get; set; } = "General";
    public decimal Price { get; set; } = 0m;
    public int TotalQuantity { get; set; } = 100;
    public int SoldQuantity { get; set; } = 0;
    public DateTime? SaleStartDate { get; set; }
    public DateTime? SaleEndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
}