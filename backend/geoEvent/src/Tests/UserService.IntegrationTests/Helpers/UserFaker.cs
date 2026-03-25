using Bogus;

namespace UserService.IntegrationTests.Helpers;

public static class UserFaker
{
    private static readonly Faker Faker = new();

    public static object ValidRegisterRequest()
    {
        var username = Faker.Internet.UserName().Replace(".", "_").Replace("-", "_");
        if (username.Length > 20) username = username[..20];
        if (username.Length < 3) username = username.PadRight(3, 'x');

        return new
        {
            username,
            email = Faker.Internet.Email(),
            password = "Test1234!",
            firstName = Faker.Name.FirstName(),
            lastName = Faker.Name.LastName(),
            birthDate = Faker.Date.Past(30, DateTime.UtcNow.AddYears(-18)).ToString("O"),
            phoneNumber = "+38761234567",
            consentGiven = true,
            consentVersion = "1.0"
        };
    }

}
