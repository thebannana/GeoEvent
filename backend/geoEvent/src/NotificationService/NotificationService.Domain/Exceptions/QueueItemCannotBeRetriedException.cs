namespace NotificationService.Domain.Exceptions;

public class QueueItemCannotBeRetriedException : Exception
{
    public QueueItemCannotBeRetriedException(int queueId)
        : base($"Queue item {queueId} cannot be retried — max attempts reached or not in failed state.") { }
}