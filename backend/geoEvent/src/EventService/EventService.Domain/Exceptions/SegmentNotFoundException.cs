namespace EventService.Domain.Exceptions;

public class SegmentNotFoundException : Exception
{
    public SegmentNotFoundException(int segmentId)
        : base($"Segment with ID {segmentId} was not found.") { }
}