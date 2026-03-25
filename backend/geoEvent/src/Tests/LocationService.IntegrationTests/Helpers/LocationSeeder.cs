using LocationService.Domain.Entities;
using LocationService.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace LocationService.IntegrationTests.Helpers;

/// <summary>
/// Seeder that inserts the full hierarchy: Continent → Country → Division → City → PostalCode
/// Returns all IDs so tests can reference them directly.
/// </summary>
public static class LocationSeeder
{
    public record SeedResult(
        int ContinentId,
        int CountryId,
        int DivisionId,
        int CityId,
        int PostalCodeId);

    public static async Task<SeedResult> SeedFullHierarchyAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<LocationDbContext>();

        var continent = new Continent
        {
            ContinentName = "Europe",
            ContinentCode = "EU"
        };
        db.Continents.Add(continent);
        await db.SaveChangesAsync();

        var country = new Country
        {
            CountryName = "Bosnia and Herzegovina",
            CountryCodeAlpha2 = "BA",
            CountryCodeAlpha3 = "BIH",
            CountryCodeNumeric = 70,
            IsActive = true,
            ContinentId = continent.ContinentId
        };
        db.Countries.Add(country);
        await db.SaveChangesAsync();

        var division = new AdministrativeDivision
        {
            DivisionName = "Federation of BiH",
            DivisionCode = "BIH-FBiH",
            DivisionType = "Federation",
            Level = 1,
            Latitude = 44.0m,
            Longitude = 17.5m,
            IsActive = true,
            CountryId = country.CountryId
        };
        db.AdministrativeDivisions.Add(division);
        await db.SaveChangesAsync();

        var city = new City
        {
            CityName = "Sarajevo",
            NormalizedName = "sarajevo",
            Latitude = 43.8563m,
            Longitude = 18.4131m,
            IsActive = true,
            DivisionId = division.DivisionId
        };
        db.Cities.Add(city);
        await db.SaveChangesAsync();

        var postal = new PostalCode
        {
            Code = "71000",
            Latitude = 43.8563m,
            Longitude = 18.4131m,
            CityId = city.CityId
        };
        db.PostalCodes.Add(postal);
        await db.SaveChangesAsync();

        return new SeedResult(
            continent.ContinentId,
            country.CountryId,
            division.DivisionId,
            city.CityId,
            postal.PostalCodeId);
    }
}
