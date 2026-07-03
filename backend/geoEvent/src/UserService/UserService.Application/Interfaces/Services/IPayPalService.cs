using UserService.Application.Common;
using UserService.Application.DTOs;

namespace UserService.Application.Interfaces.Services;

public interface IPayPalService
{
    Task<ServiceResult<PayPalStatusDto>> GetStatusAsync();
}