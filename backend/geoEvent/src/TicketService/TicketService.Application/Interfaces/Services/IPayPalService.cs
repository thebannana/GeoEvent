using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface IPayPalService
{
    Task<ServiceResult<PayPalOrderResponseDto>> CreateOrderAsync(decimal amount, string currency, string referenceId);
    Task<ServiceResult<PayPalCaptureResponseDto>> CaptureOrderAsync(string orderId);
}

public class PayPalOrderResponseDto
{
    public string OrderId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ApproveLink { get; set; } = string.Empty;
}

public class PayPalCaptureResponseDto
{
    public string Id { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
