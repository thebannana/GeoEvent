using TicketService.Application.Common;
using TicketService.Application.DTOs;

namespace TicketService.Application.Interfaces.Services;

public interface IPayPalService
{
    Task<ServiceResult<PayPalOrderResponseDto>> CreateOrderAsync(
        decimal amount,
        string currency,
        string referenceId,
        string returnUrl,
        string cancelUrl);

    Task<ServiceResult<PayPalOrderDetailsDto>> GetOrderAsync(string orderId);

    Task<ServiceResult<PayPalCaptureResponseDto>> CaptureOrderAsync(string orderId);

    Task<ServiceResult<PayPalRefundResponseDto>> RefundCaptureAsync(
        string captureId,
        decimal? amount,
        string currency,
        string? reason);
}