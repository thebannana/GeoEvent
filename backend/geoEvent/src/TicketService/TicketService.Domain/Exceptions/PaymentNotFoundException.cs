namespace TicketService.Domain.Exceptions;

public class PaymentNotFoundException : Exception
{
    public PaymentNotFoundException(int paymentId)
        : base($"Payment with ID {paymentId} was not found.") { }
}