namespace MessageService.API.Contracts;
public sealed class AddUserToEventThreadRequest
{
    public int EventId { get; set; }
    public int UserId { get; set; }
    public int? AddedByUserId { get; set; }
}
