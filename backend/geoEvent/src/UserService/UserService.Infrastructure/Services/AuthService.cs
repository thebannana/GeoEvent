using System.Security.Cryptography;
using System.Text;
using MassTransit;
using Microsoft.AspNetCore.Http;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;

namespace UserService.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly PasswordService _passwordService;
    private readonly TokenService _tokenService;
    private readonly IPublishEndpoint _publishEndpoint;

    public AuthService(
        IUserRepository userRepository,
        PasswordService passwordService,
        TokenService tokenService,
        IPublishEndpoint publishEndpoint)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _tokenService = tokenService;
        _publishEndpoint = publishEndpoint;
    }

    public async Task<ServiceResult<AuthResponseDto>> RegisterAsync(
     RegisterRequestDto request, string ipAddress)
    {
        if (!request.ConsentGiven)
            return ServiceResult<AuthResponseDto>.Fail("You must accept the terms.");

        if (await _userRepository.EmailExistsAsync(request.Email))
            return ServiceResult<AuthResponseDto>.Conflict("Email already in use.");

        if (await _userRepository.UsernameExistsAsync(request.Username))
            return ServiceResult<AuthResponseDto>.Conflict("Username already taken.");

        var (hash, salt) = _passwordService.HashPassword(request.Password);

        var person = new Person
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.PhoneNumber,
            BirthDate = request.BirthDate,
            ImageUrl = string.Empty
        };

        var verificationToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        var user = new User
        {
            Username = request.Username.ToLower(),
            Email = request.Email.ToLower(),
            PasswordHash = hash,
            PasswordSalt = salt,
            CreatedAt = DateTime.UtcNow,
            ConsentGivenAt = DateTime.UtcNow,
            ConsentVersion = request.ConsentVersion,
            EmailVerificationToken = verificationToken,
            EmailVerificationTokenExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        await _userRepository.CreateAsync(user, person);

        await _publishEndpoint.Publish(new UserRegisteredMessage(
            user.PersonId, user.Email, user.Username, person.FirstName, DateTime.UtcNow));

        await _publishEndpoint.Publish(new EmailVerificationRequestedMessage(
            user.PersonId, user.Email, verificationToken,
            user.EmailVerificationTokenExpiresAt!.Value));

        // ← Do NOT call BuildAuthResponseAsync here — user is not verified yet
        return ServiceResult<AuthResponseDto>.Ok(null!);

        // Or return a dedicated RegisterResponseDto that only has a success message,
        // not tokens. Depends on your API contract.
    }

    public async Task<ServiceResult<AuthResponseDto>> LoginAsync(
        LoginRequestDto request, string ipAddress)
    {
        var user = await _userRepository.GetByEmailOrUsernameAsync(
            request.Identifier.ToLower().Trim());

        if (user is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");

        if (user.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

        if (user.IsLockedOut())
            return ServiceResult<AuthResponseDto>.Unauthorized(
                $"Account locked until {user.LockoutUntil:HH:mm} UTC.");

        if (!user.IsVerified)
            return ServiceResult<AuthResponseDto>.Forbidden("Email not verified.");

        if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
        {
            user.RegisterFailedLogin();
            await _userRepository.UpdateAsync(user);
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        user.RegisterSuccessfulLogin(ipAddress);
        await _userRepository.UpdateAsync(user);
        return await BuildAuthResponseAsync(user, ipAddress, request.DeviceInfo);
    }

    public async Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(
        string refreshToken, string ipAddress)
    {
        var hash = Convert.ToBase64String(
            SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));

        var stored = await _userRepository.GetActiveRefreshTokenAsync(hash);
        if (stored is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid or expired refresh token.");

        if (stored.User!.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

        if (!stored.User.IsVerified)
            return ServiceResult<AuthResponseDto>.Forbidden("Email not verified.");

        stored.Revoke();
        await _userRepository.RevokeRefreshTokenAsync(hash);
        await _userRepository.CleanupExpiredTokensAsync(stored.User.PersonId);

        return await BuildAuthResponseAsync(stored.User, ipAddress, stored.DeviceInfo);
    }

    public async Task<ServiceResult<bool>> LogoutAsync(string refreshToken)
    {
        var hash = Convert.ToBase64String(
            SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));
        await _userRepository.RevokeRefreshTokenAsync(hash);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> RevokeAllSessionsAsync(int userId)
    {
        await _userRepository.RevokeAllUserTokensAsync(userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var user = await _userRepository.GetByEmailAsync(dto.Email);
        // Always return Ok to prevent email enumeration
        if (user is null)
            return ServiceResult<bool>.Ok(true);

        user.PasswordResetToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        user.PasswordResetTokenExpiresAt = DateTime.UtcNow.AddHours(1);
        await _userRepository.UpdateAsync(user);

        await _publishEndpoint.Publish(new PasswordResetRequestedMessage(
            user.PersonId,
            user.Email,
            user.PasswordResetToken,
            user.PasswordResetTokenExpiresAt.Value));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ResetPasswordAsync(ResetPasswordDto dto)
    {
        var user = await _userRepository.GetByResetTokenAsync(dto.Token);
        if (user is null || !user.IsPasswordResetTokenValid(dto.Token))
            return ServiceResult<bool>.Unauthorized("Invalid or expired reset token.");

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);
        user.PasswordHash = hash;
        user.PasswordSalt = salt;
        user.PasswordResetToken = null;
        user.PasswordResetTokenExpiresAt = null;

        await _userRepository.RevokeAllUserTokensAsync(user.PersonId);
        await _userRepository.UpdateAsync(user);
        return ServiceResult<bool>.Ok(true);
    }

    private async Task<ServiceResult<AuthResponseDto>> BuildAuthResponseAsync(
        User user, string ipAddress, string? deviceInfo = null)
    {
        var accessToken = _tokenService.GenerateAccessToken(user);
        var (rawToken, tokenHash) = _tokenService.GenerateRefreshToken();

        var refreshToken = new RefreshToken
        {
            TokenHash = tokenHash,
            UserId = user.PersonId,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            IpAddress = ipAddress,
            DeviceInfo = deviceInfo
        };

        await _userRepository.AddRefreshTokenAsync(refreshToken);

        return ServiceResult<AuthResponseDto>.Ok(new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = rawToken,
            ExpiresAt = refreshToken.ExpiresAt,
            User = new UserProfileDto
            {
                UserId = user.PersonId,
                Username = user.Username,
                Email = user.Email,
                FirstName = user.Person!.FirstName,
                LastName = user.Person.LastName,
                ImageUrl = user.Person.ImageUrl,
                Role = user.Role.ToString(),
                IsVerified = user.IsVerified,
                CreatedAt = user.CreatedAt,
                CityId = user.Person.CityId
            }
        });
    }
}
