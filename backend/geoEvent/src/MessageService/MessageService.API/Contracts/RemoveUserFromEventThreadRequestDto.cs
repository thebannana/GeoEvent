namespace MessageService.API.Contracts;

public sealed class RemoveUserFromEventThreadRequest
{
    public int EventId { get; set; }
    public int UserId { get; set; }
}
