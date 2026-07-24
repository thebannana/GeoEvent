using System.Security.Cryptography;
using System.Text;
using MassTransit;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Users;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;
using UserService.Domain.Enums;

namespace UserService.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly PasswordService _passwordService;
    private readonly TokenService _tokenService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository userRepository,
        PasswordService passwordService,
        TokenService tokenService,
        IPublishEndpoint publishEndpoint,
        ILogger<AuthService> logger)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _tokenService = tokenService;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<ServiceResult<AuthResponseDto>> RegisterAsync(RegisterRequestDto request, string ipAddress)
    {
        if (!request.ConsentGiven)
            return ServiceResult<AuthResponseDto>.Fail("You must accept the terms.", 400);

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var normalizedUsername = request.Username.Trim().ToLowerInvariant();

        if (await _userRepository.EmailExistsAsync(normalizedEmail))
            return ServiceResult<AuthResponseDto>.Conflict("Email already in use.");

        if (await _userRepository.UsernameExistsAsync(normalizedUsername))
            return ServiceResult<AuthResponseDto>.Conflict("Username already taken.");

        var (hash, salt) = _passwordService.HashPassword(request.Password);

        var person = new Person
        {
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PhoneNumber = request.PhoneNumber.Trim(),
            BirthDate = request.BirthDate,
            ImageUrl = string.Empty
        };

        var user = new User
        {
            Username = normalizedUsername,
            Email = normalizedEmail,
            CreatedAt = DateTime.UtcNow
        };

        user.ChangePassword(hash, salt);
        user.SetRole(UserRole.User);

        var consentVersion = string.IsNullOrWhiteSpace(request.ConsentVersion)
            ? "1.0"
            : request.ConsentVersion.Trim();

        user.RecordConsent(consentVersion);

        await _userRepository.CreateAsync(user, person);
        await _userRepository.SaveChangesAsync();

        try
        {
            await _publishEndpoint.Publish(new UserRegisteredMessage(
                user.PersonId,
                user.Email,
                user.Username,
                person.FirstName,
                DateTime.UtcNow));
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "User {UserId} was created, but UserRegisteredMessage publish failed.",
                user.PersonId);
        }

        return await BuildAuthResponseAsync(user, ipAddress);
    }

    public async Task<ServiceResult<AuthResponseDto>> LoginAsync(LoginRequestDto request, string ipAddress)
    {
        var identifier = request.Identifier.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailOrUsernameAsync(identifier);

        if (user is null)
        {
            _logger.LogWarning("Failed login attempt for unknown user: {Identifier}", identifier);
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        if (user.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

        if (user.IsLockedOut())
        {
            return ServiceResult<AuthResponseDto>.Unauthorized(
                $"Account locked until {user.LockoutUntil:HH:mm} UTC.");
        }

        if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
        {
            _logger.LogWarning("Invalid password for user: {Identifier}", identifier);
            user.RegisterFailedLogin();
            await _userRepository.UpdateAsync(user);
            await _userRepository.SaveChangesAsync();

            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        user.RegisterSuccessfulLogin(ipAddress);
        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        _logger.LogInformation("Successful login for user: {Identifier}", identifier);

        return await BuildAuthResponseAsync(user, ipAddress, request.DeviceInfo);
    }

    public async Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string ipAddress)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid or expired refresh token.");

        var hash = ComputeRefreshTokenHash(refreshToken);
        var stored = await _userRepository.GetActiveRefreshTokenAsync(hash);

        if (stored is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid or expired refresh token.");

        if (stored.User is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid refresh token.");

        if (stored.User.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

        await _userRepository.RevokeRefreshTokenAsync(hash);
        await _userRepository.CleanupExpiredTokensAsync(stored.User.PersonId);

        return await BuildAuthResponseAsync(stored.User, ipAddress, stored.DeviceInfo);
    }

    public async Task<ServiceResult<bool>> LogoutAsync(string refreshToken)
    {
        if (string.IsNullOrWhiteSpace(refreshToken))
            return ServiceResult<bool>.Ok(true);

        var hash = ComputeRefreshTokenHash(refreshToken);
        await _userRepository.RevokeRefreshTokenAsync(hash);

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail);

        if (user is null)
            return ServiceResult<bool>.Ok(true);

        if (user.IsBanned)
            return ServiceResult<bool>.Ok(true);

        var rawToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        var tokenHash = ComputeSha256(rawToken);
        var now = DateTime.UtcNow;
        var expiresAt = now.AddMinutes(30);

        await _userRepository.InvalidateActivePasswordResetTokensAsync(user.PersonId);

        var resetToken = new PasswordResetToken(
            user.PersonId,
            tokenHash,
            now,
            expiresAt);

        await _userRepository.CreatePasswordResetTokenAsync(resetToken);
        await _userRepository.SaveChangesAsync();

        await _publishEndpoint.Publish(new PasswordResetRequestedMessage(
            user.PersonId,
            user.Email,
            rawToken,
            expiresAt));

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> ResetPasswordAsync(ResetPasswordDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail);

        if (user is null)
            return ServiceResult<bool>.Fail("Invalid reset request.", 400);

        var tokenHash = ComputeSha256(dto.Token);
        var resetToken = await _userRepository.GetActivePasswordResetTokenAsync(user.PersonId, tokenHash);

        if (resetToken is null)
            return ServiceResult<bool>.Fail("Invalid reset request.", 400);

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);

        user.ChangePassword(hash, salt);
        resetToken.MarkAsUsed();

        await _userRepository.UpdateAsync(user);
        await _userRepository.MarkPasswordResetTokenUsedAsync(resetToken);
        await _userRepository.RevokeAllUserTokensAsync(user.PersonId);
        await _userRepository.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<bool>> RevokeAllSessionsAsync(int userId)
    {
        await _userRepository.RevokeAllUserTokensAsync(userId);
        return ServiceResult<bool>.Ok(true);
    }

    public async Task<ServiceResult<AuthResponseDto>> AdminLoginAsync(LoginRequestDto request, string ipAddress)
    {
        var identifier = request.Identifier.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailOrUsernameAsync(identifier);

        if (user is null)
        {
            _logger.LogWarning("Failed admin login attempt for unknown user: {Identifier}", identifier);
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        if (user.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

        if (user.IsLockedOut())
        {
            return ServiceResult<AuthResponseDto>.Unauthorized(
                $"Account locked until {user.LockoutUntil:HH:mm} UTC.");
        }

        if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
        {
            _logger.LogWarning("Invalid password for admin login: {Identifier}", identifier);
            user.RegisterFailedLogin();
            await _userRepository.UpdateAsync(user);
            await _userRepository.SaveChangesAsync();

            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        if (user.Role != UserRole.Admin)
        {
            _logger.LogWarning("Non-admin attempted admin login: {Identifier}", identifier);
            return ServiceResult<AuthResponseDto>.Forbidden("Admin access only.");
        }

        user.RegisterSuccessfulLogin(ipAddress);
        await _userRepository.UpdateAsync(user);
        await _userRepository.SaveChangesAsync();

        _logger.LogInformation("Successful admin login for user: {Identifier}", identifier);

        return await BuildAuthResponseAsync(user, ipAddress, request.DeviceInfo);
    }

    private async Task<ServiceResult<AuthResponseDto>> BuildAuthResponseAsync(
        User user,
        string ipAddress,
        string? deviceInfo = null)
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
        await _userRepository.SaveChangesAsync();

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
                FirstName = user.Person?.FirstName ?? string.Empty,
                LastName = user.Person?.LastName ?? string.Empty,
                ImageUrl = user.Person?.ImageUrl,
                Role = user.Role.ToString(),
                CreatedAt = user.CreatedAt
            }
        });
    }

    private static string ComputeRefreshTokenHash(string refreshToken) =>
        Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));

    private static string ComputeSha256(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}