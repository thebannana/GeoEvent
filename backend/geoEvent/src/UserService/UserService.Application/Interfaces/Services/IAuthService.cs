using UserService.Application.Common;
using UserService.Application.DTOs;

namespace UserService.Application.Interfaces.Services;

public interface IAuthService
{
    Task<ServiceResult<AuthResponseDto>> RegisterAsync(RegisterRequestDto request, string ipAddress);
    Task<ServiceResult<AuthResponseDto>> LoginAsync(LoginRequestDto request, string ipAddress);
    Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string ipAddress);
    Task<ServiceResult<bool>> LogoutAsync(string refreshToken);
    Task<ServiceResult<bool>> RevokeAllSessionsAsync(int userId);
    Task<ServiceResult<bool>> ForgotPasswordAsync(ForgotPasswordDto dto);
    Task<ServiceResult<bool>> ResetPasswordAsync(ResetPasswordDto dto);

}
