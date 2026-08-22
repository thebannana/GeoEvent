using EventService.Domain.Entities;

namespace EventService.Application.DTOs;

public sealed class RankedEvent
{
    public required Event Event { get; init; }

    public required double Score { get; init; }
}