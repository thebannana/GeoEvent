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

public class TicketTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public TicketTests(CustomWebApplicationFactory factory) : base(factory) { }

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

    /// <summary>Creates a reservation and confirms it, returning the issued ticket IDs.</summary>
    private async Task<List<int>> CreateConfirmedTicketsAsync(
        HttpClient client, int userId, int eventId, int eventTicketId, int quantity = 1)
    {
        SetAuth(client, userId);
        var resResponse = await client.PostAsJsonAsync("/api/reservations", new
        {
            eventId,
            eventTicketId,
            quantity,
            currency = "BAM"
        });
        resResponse.EnsureSuccessStatusCode();
        var resBody = await resResponse.Content.ReadFromJsonAsync<JsonElement>();
        var reservationId = resBody.GetProperty("reservationId").GetInt32();
        var totalAmount = resBody.GetProperty("totalAmount").GetDecimal();
        var currency = resBody.GetProperty("currency").GetString()!;

        SetAuth(client, userId);
        var confirmResponse = await client.PostAsJsonAsync($"/api/reservations/{reservationId}/confirm", new
        {
            paymentReference = $"PAY-{Guid.NewGuid():N}"[..30],
            paymentMethod = 0,
            amount = totalAmount,
            currency
        });
        confirmResponse.EnsureSuccessStatusCode();
        var confirmBody = await confirmResponse.Content.ReadFromJsonAsync<JsonElement>();

        return confirmBody.GetProperty("tickets")
            .EnumerateArray()
            .Select(t => t.GetProperty("ticketId").GetInt32())
            .ToList();
    }

    // ── GET /api/tickets/{ticketId} ───────────────────────────────

    [Fact]
    public async Task GetTicketById_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/tickets/1");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetTicketById_AsOwner_Returns200()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 1);
        var response = await client.GetAsync($"/api/tickets/{ticketIds[0]}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("ticketId").GetInt32().Should().Be(ticketIds[0]);
        body.GetProperty("status").GetString().Should().Be("Active");
    }

    [Fact]
    public async Task GetTicketById_AsNonOwner_Returns403()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 2);
        var response = await client.GetAsync($"/api/tickets/{ticketIds[0]}");

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetTicketById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);
        var response = await client.GetAsync("/api/tickets/99999");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // ── GET /api/tickets/my ───────────────────────────────────────

    [Fact]
    public async Task GetMyTickets_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/tickets/my");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task GetMyTickets_WithAuth_Returns200WithItems()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId, quantity: 2);

        SetAuth(client, 1);
        var response = await client.GetAsync("/api/tickets/my");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("items").GetArrayLength().Should().Be(2);
    }

    [Fact]
    public async Task GetMyTickets_EmptyForNewUser_Returns200EmptyList()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 99);
        var response = await client.GetAsync("/api/tickets/my");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("items").GetArrayLength().Should().Be(0);
    }

    // ── PATCH /api/tickets/{ticketId}/cancel ──────────────────────

    [Fact]
    public async Task CancelTicket_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PatchAsync("/api/tickets/1/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task CancelTicket_AsOwner_Returns204()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 1);
        var response = await client.PatchAsync($"/api/tickets/{ticketIds[0]}/cancel", null);

        response.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task CancelTicket_AsNonOwner_Returns403()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 2);
        var response = await client.PatchAsync($"/api/tickets/{ticketIds[0]}/cancel", null);

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CancelTicket_NotFound_Returns404()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1);
        var response = await client.PatchAsync("/api/tickets/99999/cancel", null);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task CancelTicket_AlreadyCancelled_Returns400()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 1);
        await client.PatchAsync($"/api/tickets/{ticketIds[0]}/cancel", null);
        var second = await client.PatchAsync($"/api/tickets/{ticketIds[0]}/cancel", null);

        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    // ── POST /api/tickets/validate ────────────────────────────────

    [Fact]
    public async Task ValidateTicket_WithoutAuth_Returns401()
    {
        var client = Factory.CreateClient();
        var response = await client.PostAsync("/api/tickets/validate?qrCode=someCode", null);
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ValidateTicket_AsUser_Returns403()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 1, "User"); // Not Staff/Admin/Organizer
        var response = await client.PostAsync("/api/tickets/validate?qrCode=someCode", null);
        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task ValidateTicket_AsStaff_ValidQrCode_Returns200()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        // Fetch the QR code
        SetAuth(client, 1);
        var ticketResp = await client.GetAsync($"/api/tickets/{ticketIds[0]}");
        var ticketBody = await ticketResp.Content.ReadFromJsonAsync<JsonElement>();
        var qrCode = ticketBody.GetProperty("qrCode").GetString()!;

        SetAuth(client, 99, "Staff");
        var response = await client.PostAsync($"/api/tickets/validate?qrCode={Uri.EscapeDataString(qrCode)}", null);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("status").GetString().Should().Be("Used");
    }

    [Fact]
    public async Task ValidateTicket_AsStaff_InvalidQrCode_Returns400()
    {
        var client = Factory.CreateClient();
        SetAuth(client, 99, "Staff");

        var response = await client.PostAsync("/api/tickets/validate?qrCode=tooshort", null);

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task ValidateTicket_AsStaff_AlreadyUsedTicket_Returns400()
    {
        var eventTicketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();
        var ticketIds = await CreateConfirmedTicketsAsync(client, userId: 1, eventId: 1, eventTicketId: eventTicketId);

        SetAuth(client, 1);
        var ticketResp = await client.GetAsync($"/api/tickets/{ticketIds[0]}");
        var ticketBody = await ticketResp.Content.ReadFromJsonAsync<JsonElement>();
        var qrCode = ticketBody.GetProperty("qrCode").GetString()!;
        var encoded = Uri.EscapeDataString(qrCode);

        SetAuth(client, 99, "Staff");
        await client.PostAsync($"/api/tickets/validate?qrCode={encoded}", null); // first use
        var second = await client.PostAsync($"/api/tickets/validate?qrCode={encoded}", null); // already used

        second.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
}
