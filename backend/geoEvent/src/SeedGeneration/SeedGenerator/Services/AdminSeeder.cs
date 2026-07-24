using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SeedGeneration.SeedGenerator.Configuration;
using SeedGeneration.SeedGenerator.Interfaces;
using UserService.Domain.Entities;
using UserService.Domain.Enums;
using UserService.Infrastructure.Persistence;
using UserService.Infrastructure.Services;

namespace GeoEvent.SeedGenerator.Seeders;

public class AdminSeeder : ISeeder
{
    private readonly UserDbContext _dbContext;
    private readonly PasswordService _passwordService;
    private readonly IReadOnlyList<SeedAdminOptions> _admins;
    private readonly ILogger<AdminSeeder> _logger;

    public AdminSeeder(
        UserDbContext dbContext,
        PasswordService passwordService,
        IOptions<SeedSettings> options,
        ILogger<AdminSeeder> logger)
    {
        _dbContext = dbContext;
        _passwordService = passwordService;
        _admins = options.Value.SeedAdmins ?? new List<SeedAdminOptions>();
        _logger = logger;
    }

    public string Name => "admins";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_admins.Count == 0)
        {
            _logger.LogWarning("No admin users configured in SeedAdmins.");
            return;
        }

        foreach (var admin in _admins)
        {
            if (string.IsNullOrWhiteSpace(admin.Email) || string.IsNullOrWhiteSpace(admin.Username))
            {
                _logger.LogWarning("Skipping admin entry because Email or Username is missing.");
                continue;
            }

            var normalizedEmail = admin.Email.Trim().ToLowerInvariant();
            var normalizedUsername = admin.Username.Trim().ToLowerInvariant();

            var existingUser = await _dbContext.Users
                .Include(x => x.Person)
                .FirstOrDefaultAsync(
                    x => x.Email == normalizedEmail || x.Username == normalizedUsername,
                    cancellationToken);

            if (existingUser is not null)
            {
                var updated = false;

                if (existingUser.Role != UserRole.Admin)
                {
                    existingUser.SetRole(UserRole.Admin);
                    updated = true;
                }

                if (existingUser.Person is not null)
                {
                    existingUser.Person.FirstName = admin.FirstName.Trim();
                    existingUser.Person.LastName = admin.LastName.Trim();
                    existingUser.Person.PhoneNumber = admin.PhoneNumber.Trim();
                    existingUser.Person.BirthDate = admin.BirthDate;
                }

                existingUser.RecordConsent(admin.ConsentVersion);

                await _dbContext.SaveChangesAsync(cancellationToken);

                if (updated)
                {
                    _logger.LogInformation("Existing user promoted to admin: {Username}", existingUser.Username);
                }
                else
                {
                    _logger.LogInformation("Admin already exists: {Username}", existingUser.Username);
                }

                continue;
            }

            var person = new Person
            {
                FirstName = admin.FirstName.Trim(),
                LastName = admin.LastName.Trim(),
                PhoneNumber = admin.PhoneNumber.Trim(),
                BirthDate = admin.BirthDate,
                ImageUrl = string.Empty,
                IsDeleted = false
            };

            var user = new User
            {
                Username = normalizedUsername,
                Email = normalizedEmail,
                CreatedAt = DateTime.UtcNow,
                Person = person
            };

            var (hash, salt) = _passwordService.HashPassword(admin.Password);
            user.ChangePassword(hash, salt);
            user.SetRole(UserRole.Admin);
            user.RecordConsent(admin.ConsentVersion);

            await _dbContext.People.AddAsync(person, cancellationToken);
            await _dbContext.Users.AddAsync(user, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Admin user created successfully: {Username}", user.Username);
        }
    }
}