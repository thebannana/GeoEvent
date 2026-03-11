namespace NotificationService.Domain.Exceptions;

public class QueueItemCannotBeCancelledException : Exception
{
    public QueueItemCannotBeCancelledException(int queueId)
        : base($"Queue item {queueId} cannot be cancelled in its current state.") { }
}