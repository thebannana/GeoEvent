using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using TicketService.Domain.Entities;
using TicketService.IntegrationTests.Helpers;
using TicketService.Infrastructure.Persistence;

namespace TicketService.IntegrationTests.Tests;

public class EventTicketsTests : IntegrationTestBase, IClassFixture<CustomWebApplicationFactory>
{
    public EventTicketsTests(CustomWebApplicationFactory factory) : base(factory) { }

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
            IsActive = true,
            Description = "Test ticket"
        };
        db.EventTickets.Add(ticket);
        await db.SaveChangesAsync();
        return ticket.TicketId;
    }

    // GET /api/events/{eventId}/tickets

    [Fact]
    public async Task GetEventTickets_ExistingEvent_Returns200WithList()
    {
        await SeedEventTicketAsync(eventId: 1);
        var client = Factory.CreateClient();

        var response = await client.GetAsync("/api/events/1/tickets");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetEventTickets_NoTickets_Returns200WithEmptyList()
    {
        var client = Factory.CreateClient();

        var response = await client.GetAsync("/api/events/999/tickets");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetArrayLength().Should().Be(0);
    }

    [Fact]
    public async Task GetEventTickets_IsAnonymous_Returns200()
    {
        // No auth header at all
        var client = Factory.CreateClient();
        var response = await client.GetAsync("/api/events/1/tickets");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    // GET /api/events/{eventId}/tickets/{eventTicketId}

    [Fact]
    public async Task GetEventTicketById_Existing_Returns200()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();

        var response = await client.GetAsync($"/api/events/1/tickets/{ticketId}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        body.GetProperty("ticketId").GetInt32().Should().Be(ticketId);
    }

    [Fact]
    public async Task GetEventTicketById_NotFound_Returns404()
    {
        var client = Factory.CreateClient();

        var response = await client.GetAsync("/api/events/1/tickets/99999");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetEventTicketById_IsAnonymous_Returns200()
    {
        var ticketId = await SeedEventTicketAsync();
        var client = Factory.CreateClient();

        var response = await client.GetAsync($"/api/events/1/tickets/{ticketId}");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
