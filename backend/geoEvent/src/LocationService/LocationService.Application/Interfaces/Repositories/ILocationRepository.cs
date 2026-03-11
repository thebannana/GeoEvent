using LocationService.Application.Common;
using LocationService.Application.DTOs;
using LocationService.Domain.Entities;

namespace LocationService.Application.Interfaces.Repositories;

public interface ILocationRepository
{
    // ── Continents ────────────────────────────────────────────
    Task<List<Continent>> GetAllContinentsAsync();
    Task<Continent?> GetContinentByIdAsync(int continentId);

    // ── Countries ─────────────────────────────────────────────
    Task<List<Country>> GetCountriesAsync(CountryFilterDto filter);       // replace GetAllCountriesAsync — use filter
    Task<List<Country>> GetCountriesByContinentAsync(int continentId);
    Task<Country?> GetCountryByIdAsync(int countryId);
    Task<Country?> GetCountryByCodeAsync(string code);

    // ── Divisions ─────────────────────────────────────────────
    Task<List<AdministrativeDivision>> GetDivisionsAsync(DivisionFilterDto filter);  // replace multiple methods
    Task<AdministrativeDivision?> GetDivisionByIdAsync(int divisionId);

    // ── Cities ────────────────────────────────────────────────
    Task<PagedResult<City>> GetCitiesAsync(CityFilterDto filter);
    Task<City?> GetCityByIdAsync(int cityId);
    Task<List<City>> GetCitiesByDivisionAsync(int divisionId);
    Task<List<City>> SearchCitiesAsync(string searchTerm, int limit = 10);
    Task<List<City>> GetNearbyCitiesAsync(decimal latitude, decimal longitude, double radiusKm, int limit);  // new
    Task<List<City>> GetCitiesByCountryAsync(int countryId);


    // ── Postal Codes ──────────────────────────────────────────
    Task<List<PostalCode>> GetPostalCodesByCityAsync(int cityId);
    Task<PostalCode?> GetPostalCodeByCodeAsync(string code);
    Task<PostalCode?> GetPostalCodeByIdAsync(int postalCodeId);           // new
}
