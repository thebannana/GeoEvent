using Bogus;

namespace TicketService.IntegrationTests.Helpers;

public static class TicketFaker
{
    private static readonly Faker Faker = new();

    /// <summary>
    /// Seeds a Tickets row directly into the DB (EventTicket entity) via the API is not exposed for creation —
    /// tests must seed via EF or use a pre-seeded fixture. This helper builds the seed payload.
    /// </summary>
    public static object ValidEventTicketSeed(int eventId, int totalQuantity = 50, decimal price = 10m) => new
    {
        EventId = eventId,
        TicketType = "General",
        Price = price,
        TotalQuantity = totalQuantity,
        SoldQuantity = 0,
        IsActive = true,
        Description = "Integration test ticket type"
    };

    public static object ValidCreateReservationRequest(int eventId, int eventTicketId, int quantity = 1) => new
    {
        eventId,
        eventTicketId,
        quantity,
        currency = "BAM",
        notes = "Integration test reservation"
    };

    public static object ValidConfirmReservationRequest(decimal amount, string currency = "BAM") => new
    {
        paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
        paymentMethod = 0, // CreditCard
        amount,
        currency
    };
}
