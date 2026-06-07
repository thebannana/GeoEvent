using MassTransit;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Events;
using TicketService.Application.Interfaces.Repositories;
using TicketService.Domain.Entities;

namespace TicketService.Infrastructure.Consumers;

public class EventCreatedConsumer : IConsumer<EventCreatedMessage>
{
    private readonly ITicketRepository _repository;
    private readonly ILogger<EventCreatedConsumer> _logger;

    public EventCreatedConsumer(
        ITicketRepository repository,
        ILogger<EventCreatedConsumer> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<EventCreatedMessage> context)
    {
        var msg = context.Message;

        _logger.LogInformation(
            "Consuming EventCreatedMessage for EventId {EventId}",
            msg.EventId);

        _logger.LogInformation(
    "Creating ticket for EventId {EventId}, Capacity={Capacity}, Price={Price}, Start={Start}, End={End}",
    msg.EventId, msg.Capacity, msg.Price, msg.StartDateTime, msg.EndDateTime);

        var existingTickets = await _repository.GetEventTicketsByEventAsync(msg.EventId);
        if (existingTickets.Any())
        {
            _logger.LogInformation(
                "Event tickets already exist for EventId {EventId}. Skipping duplicate creation.",
                msg.EventId);
            return;
        }

        var saleStart = DateTime.UtcNow;
        var saleEnd = msg.StartDateTime;

        if (saleEnd <= saleStart)
        {
            _logger.LogWarning(
                "Ticket creation skipped for EventId {EventId} because event start is not in the future. Start={StartDateTime}, Now={Now}",
                msg.EventId,
                msg.StartDateTime,
                saleStart);
            return;
        }

        var eventTicket = new EventTicket
        {
            EventId = msg.EventId,
            TicketType = "General Admission",
            Description = "Default ticket",
            Price = msg.Price,
            TotalQuantity = Math.Max(0, msg.Capacity),
            SoldQuantity = 0,
            IsActive = true,
            SaleStartDate = saleStart,
            SaleEndDate = saleEnd
        };

        await _repository.CreateEventTicketAsync(eventTicket);

        _logger.LogInformation(
            "Created default ticket for EventId {EventId}. Price={Price}, Capacity={Capacity}, SaleStart={SaleStart}, SaleEnd={SaleEnd}",
            msg.EventId,
            eventTicket.Price,
            eventTicket.TotalQuantity,
            eventTicket.SaleStartDate,
            eventTicket.SaleEndDate);
    }
}