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

public class UserSeeder : ISeeder
{
    private readonly UserDbContext _dbContext;
    private readonly PasswordService _passwordService;
    private readonly IReadOnlyList<SeedUserOptions> _users;
    private readonly ILogger<UserSeeder> _logger;

    public UserSeeder(
        UserDbContext dbContext,
        PasswordService passwordService,
        IOptions<SeedSettings> options,
        ILogger<UserSeeder> logger)
    {
        _dbContext = dbContext;
        _passwordService = passwordService;
        _users = options.Value.SeedUsers ?? new List<SeedUserOptions>();
        _logger = logger;
    }

    public string Name => "users";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (_users.Count == 0)
        {
            _logger.LogWarning("No regular users configured in SeedUsers.");
            return;
        }

        foreach (var seedUser in _users)
        {
            if (string.IsNullOrWhiteSpace(seedUser.Email) || string.IsNullOrWhiteSpace(seedUser.Username))
            {
                _logger.LogWarning("Skipping user entry because Email or Username is missing.");
                continue;
            }

            var normalizedEmail = seedUser.Email.Trim().ToLowerInvariant();
            var normalizedUsername = seedUser.Username.Trim().ToLowerInvariant();

            var existingUser = await _dbContext.Users
                .Include(x => x.Person)
                .FirstOrDefaultAsync(
                    x => x.Email == normalizedEmail || x.Username == normalizedUsername,
                    cancellationToken);

            if (existingUser is not null)
            {
                _logger.LogInformation("User already exists: {Username}", existingUser.Username);
                continue;
            }

            var person = new Person
            {
                FirstName = seedUser.FirstName.Trim(),
                LastName = seedUser.LastName.Trim(),
                PhoneNumber = seedUser.PhoneNumber.Trim(),
                BirthDate = seedUser.BirthDate,
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

            var (hash, salt) = PasswordService.HashPassword(seedUser.Password);
            user.ChangePassword(hash, salt);
            user.SetRole(UserRole.User);
            user.RecordConsent(seedUser.ConsentVersion);

            await _dbContext.People.AddAsync(person, cancellationToken);
            await _dbContext.Users.AddAsync(user, cancellationToken);
            await _dbContext.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("User created successfully: {Username}", user.Username);
        }
    }
}