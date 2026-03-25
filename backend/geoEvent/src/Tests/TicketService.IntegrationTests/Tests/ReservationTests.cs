using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using TicketService.Domain.Entities;
using TicketService.IntegrationTests.Helpers;
using TicketService.Infrastructure.Persistence;

namespace TicketService.IntegrationTests.Tests;

public class ReservationTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public ReservationTests(CustomWebApplicationFactory factory) : base(factory) { }

    private static void SetAuth(HttpClient client, int userId, string role = "User")
        => client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", HttpClientExtensions.GenerateJwt(userId, role));

    private async Task<int> SeedEventTicketAsync(int eventId = 1, int total = 50, decimal price = 10m)
    {
        using var scope = Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TicketDbContext>();
        var ticket = new EventTicket
        {
            EventId = eventId,
            TicketType = "General",
            Price = price,
            TotalQuantity = total,
            SoldQuantity = 0,
            IsActive = true
        };
        db.EventTickets.Add(ticket);
        await db.SaveChangesAsync();
        return ticket.TicketId;
    }

    private async Task<(int reservationId, decimal totalAmount, string currency)> CreateReservationAsync(
        HttpClient client, int userId, int eventId, int eventTicketId, int quantity = 1)
    {
        SetAuth(client, userId);
        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId,
            eventTicketId,
            quantity,
            currency = "BAM"
        });
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var reservationId = body.GetProperty("reservationId").GetInt32();
        var totalAmount = body.GetProperty("totalAmount").GetDecimal();
        var currency = body.GetProperty("currency").GetString()!;
        return (reservationId, totalAmount, currency);
    }

    // ── POST /api/reservations ────────────────────────────────────

    [Fact]
    public async Task CreateReservation_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/reservations", new { eventId = 1, eventTicketId = 1, quantity = 1 });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CreateReservation_ValidRequest_Returns201()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        SetAuth(client, 1);

        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = ticketId,
            quantity = 2,
            currency = "BAM"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("reservationId").GetInt32().Should().BeGreaterThan(0);
        body.GetProperty("status").GetString().Should().Be("Pending");
    }

    [Fact]
    public async Task CreateReservation_TicketNotFound_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);

        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = 99999,
            quantity = 1
        });

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task CreateReservation_QuantityZero_Returns400()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        SetAuth(client, 1);

        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = ticketId,
            quantity = 0
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task CreateReservation_QuantityExceedsLimit_Returns400()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        SetAuth(client, 1);

        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = ticketId,
            quantity = 11 // max is 10
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task CreateReservation_ExceedsAvailableStock_Returns400()
    {
        var ticketId = await SeedEventTicketAsync(total: 1); // only 1 available
        var client = Factory.CreateClient();
        SetAuth(client, 1);

        var response = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = ticketId,
            quantity = 2
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task CreateReservation_DuplicateActiveReservation_Returns409()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();

        await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        // Second reservation for same ticket type
        SetAuth(client, 1);
        var second = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId = 1,
            eventTicketId = ticketId,
            quantity = 1
        });

        second.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    // ── GET /api/reservations/{id} ────────────────────────────────

    [Fact]
    public async Task GetReservation_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/reservations/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetReservation_AsOwner_Returns200()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var response = await client.GetAsync($"/api/reservations/{reservationId}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("reservationId").GetInt32().Should().Be(reservationId);
    }

    [Fact]
    public async Task GetReservation_AsNonOwner_Returns403()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 2);
        var response = await client.GetAsync($"/api/reservations/{reservationId}");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetReservation_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);
        var response = await client.GetAsync("/api/reservations/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // ── GET /api/reservations/my ──────────────────────────────────

    [Fact]
    public async Task GetMyReservations_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/reservations/my");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetMyReservations_WithAuth_Returns200()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var response = await client.GetAsync("/api/reservations/my");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("items").GetArrayLength().Should().BeGreaterThan(0);
    }

    // ── POST /api/reservations/{id}/confirm ───────────────────────

    [Fact]
    public async Task ConfirmReservation_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/reservations/1/confirm", new
        {
            paymentReference = "PAY-TEST-001",
            paymentMethod = 0,
            amount = 10m,
            currency = "BAM"
        });
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ConfirmReservation_AsOwner_Returns200()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, totalAmount, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var response = await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Confirmed");
    }

    [Fact]
    public async Task ConfirmReservation_AsNonOwner_Returns403()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, totalAmount, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 2);
        var response = await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task ConfirmReservation_WrongAmount_Returns400()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, _, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var response = await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = 999m, // wrong
            currency
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ConfirmReservation_DuplicatePaymentReference_Returns409()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m, total: 50);
        var client = Factory.CreateClient();
        var payRef = $"PAY-{Guid.NewGuid():N}"[..30];

        // First reservation + confirm
        var (r1, amount1, currency1) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);
        SetAuth(client, 1);
        await client.PostAsJsonAsync($"/api/reservations/{r1}/confirm", new
        {
            paymentReference = payRef,
            paymentMethod = 0,
            amount = amount1,
            currency = currency1
        });

        // Second reservation by different user, same payRef
        var ticketId2 = await SeedEventTicketAsync(eventId: 2, total: 50, price: 10m);
        var client2 = Factory.CreateClient();
        var (r2, amount2, currency2) = await CreateReservationAsync(client2, userId: 2, eventId: 2, eventTicketId: ticketId2);
        SetAuth(client2, 2);
        var response = await client2.PostAsJsonAsync($"/api/reservations/{r2}/confirm", new
        {
            paymentReference = payRef, // same reference
            paymentMethod = 0,
            amount = amount2,
            currency = currency2
        });

        response.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task ConfirmReservation_AlreadyConfirmed_Returns400()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, totalAmount, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var confirmBody = new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        };
        await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", confirmBody);

        // Try confirming again
        var second = await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });

        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── PATCH /api/reservations/{id}/cancel ───────────────────────

    [Fact]
    public async Task CancelReservation_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PatchAsync("/api/reservations/1/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CancelReservation_AsOwner_Returns204()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        var response = await client.PatchAsync($"/api/reservations/{reservationId}/cancel", null);

        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task CancelReservation_AsNonOwner_Returns403()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 2);
        var response = await client.PatchAsync($"/api/reservations/{reservationId}/cancel", null);

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CancelReservation_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);
        var response = await client.PatchAsync("/api/reservations/99999/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // ── GET /api/reservations/{id}/tickets ────────────────────────

    [Fact]
    public async Task GetReservationTickets_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/reservations/1/tickets");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetReservationTickets_AfterConfirm_ReturnsTickets()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, totalAmount, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId, quantity: 2);

        SetAuth(client, 1);
        await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });

        var response = await client.GetAsync($"/api/reservations/{reservationId}/tickets");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(2); // one per quantity
    }

    [Fact]
    public async Task GetReservationTickets_AsNonOwner_Returns403()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 2);
        var response = await client.GetAsync($"/api/reservations/{reservationId}/tickets");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    // ── GET /api/reservations/{id}/payments ───────────────────────

    [Fact]
    public async Task GetReservationPayments_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/reservations/1/payments");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetReservationPayments_AfterConfirm_ReturnsPayment()
    {
        var ticketId = await SeedEventTicketAsync(price: 10m);
        var client = Factory.CreateClient();
        var (reservationId, totalAmount, currency) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 1);
        await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });

        var response = await client.GetAsync($"/api/reservations/{reservationId}/payments");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(1);
        body[0].GetProperty("status").GetString().Should().Be("Completed");
    }

    [Fact]
    public async Task GetReservationPayments_AsNonOwner_Returns403()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var (reservationId, _, _) = await CreateReservationAsync(client, userId: 1, eventId: 1, eventTicketId: ticketId);

        SetAuth(client, 2);
        var response = await client.GetAsync($"/api/reservations/{reservationId}/payments");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }
}
