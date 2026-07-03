using MassTransit;
using MassTransit.Transports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Users;
using System.Security.Cryptography;
using System.Text;
using UserService.Application.Common;
using UserService.Application.DTOs;
using UserService.Application.Interfaces.Repositories;
using UserService.Application.Interfaces.Services;
using UserService.Domain.Entities;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Repositories;

namespace UserService.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly PasswordService _passwordService;
    private readonly TokenService _tokenService;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly UserDbContext _context;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository userRepository,
        PasswordService passwordService,
        TokenService tokenService,
        IPublishEndpoint publishEndpoint,
        UserDbContext context,
        ILogger<AuthService> logger)
    {
        _userRepository = userRepository;
        _passwordService = passwordService;
        _tokenService = tokenService;
        _publishEndpoint = publishEndpoint;
        _context = context;
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
            PasswordHash = hash,
            PasswordSalt = salt,
            Role = Domain.Enums.UserRole.User,
            CreatedAt = DateTime.UtcNow,
            ConsentGivenAt = DateTime.UtcNow,
            ConsentVersion = string.IsNullOrWhiteSpace(request.ConsentVersion) ? "1.0" : request.ConsentVersion.Trim(),
        };

        await _userRepository.CreateAsync(user, person);

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
            _logger.LogError(ex,
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
            return ServiceResult<AuthResponseDto>.Unauthorized(
                $"Account locked until {user.LockoutUntil:HH:mm} UTC.");

        if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
        {
            _logger.LogWarning("Invalid password for user: {Identifier}", identifier);
            user.RegisterFailedLogin();
            await _userRepository.UpdateAsync(user);
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid credentials.");
        }

        user.RegisterSuccessfulLogin(ipAddress);
        await _userRepository.UpdateAsync(user);
        _logger.LogInformation("Successful login for user: {Identifier}", identifier);

        return await BuildAuthResponseAsync(user, ipAddress, request.DeviceInfo);
    }

    public async Task<ServiceResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken, string ipAddress)
    {
        var hash = Convert.ToBase64String(
            SHA256.HashData(Encoding.UTF8.GetBytes(refreshToken)));

        var stored = await _userRepository.GetActiveRefreshTokenAsync(hash);

        if (stored is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid or expired refresh token.");

        if (stored.User is null)
            return ServiceResult<AuthResponseDto>.Unauthorized("Invalid refresh token.");

        if (stored.User.IsBanned)
            return ServiceResult<AuthResponseDto>.Forbidden("Account is banned.");

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

    public async Task<ServiceResult<bool>> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var normalizedEmail = dto.Email.Trim().ToLowerInvariant();

        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Email.ToLower() == normalizedEmail);

        if (user == null)
            return ServiceResult<bool>.Ok(true);

        var rawToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        var tokenHash = ComputeSha256(rawToken);
        var expiresAt = DateTime.UtcNow.AddMinutes(30);

        var existingTokens = await _context.PasswordResetTokens
            .Where(x => x.UserId == user.PersonId && x.UsedAt == null && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync();

        foreach (var token in existingTokens)
        {
            token.UsedAt = DateTime.UtcNow;
        }

        _context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UserId = user.PersonId,
            TokenHash = tokenHash,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = expiresAt
        });

        await _context.SaveChangesAsync();

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

        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Email.ToLower() == normalizedEmail);

        if (user == null)
            return ServiceResult<bool>.Fail("Invalid reset request.");

        var tokenHash = ComputeSha256(dto.Token);

        var resetToken = await _context.PasswordResetTokens
            .Where(x => x.UserId == user.PersonId
                     && x.TokenHash == tokenHash
                     && x.UsedAt == null
                     && x.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        if (resetToken == null)
            return ServiceResult<bool>.Fail("Token is invalid or expired.");

        var (hash, salt) = _passwordService.HashPassword(dto.NewPassword);
        user.PasswordHash = hash;
        user.PasswordSalt = salt;

        resetToken.UsedAt = DateTime.UtcNow;

        await _userRepository.RevokeAllUserTokensAsync(user.PersonId);
        await _context.SaveChangesAsync();

        return ServiceResult<bool>.Ok(true);
    }

    private static string ComputeSha256(string value)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes);
    }

    public async Task<ServiceResult<bool>> RevokeAllSessionsAsync(int userId)
    {
        await _userRepository.RevokeAllUserTokensAsync(userId);
        return ServiceResult<bool>.Ok(true);
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
                CreatedAt = user.CreatedAt,
            }
        });
    }
}