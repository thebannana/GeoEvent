using Bogus;

namespace EventService.IntegrationTests.Helpers;

public static class EventFaker
{
    private static readonly Faker Faker = new();

    public static object ValidCreateEventRequest(int? venueId = null, int? cityId = null) => new
    {
        title = Faker.Lorem.Sentence(3)[..Math.Min(50, Faker.Lorem.Sentence(3).Length)],
        description = Faker.Lorem.Paragraph(),
        latitude = (decimal)Faker.Address.Latitude(),
        longitude = (decimal)Faker.Address.Longitude(),
        startDateTime = DateTime.UtcNow.AddDays(7).ToString("O"),
        endDateTime = DateTime.UtcNow.AddDays(7).AddHours(3).ToString("O"),
        capacity = 100,
        price = 0m,
        isOnline = false,
        locale = "bs-BA",
        venueId,
        cityId
    };

    public static object ValidCreateVenueRequest() => new
    {
        name = Faker.Company.CompanyName()[..Math.Min(50, Faker.Company.CompanyName().Length)],
        latitude = (decimal)Faker.Address.Latitude(),
        longitude = (decimal)Faker.Address.Longitude(),
        cityId = 1
    };
}
