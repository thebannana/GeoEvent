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
    Task<List<Country>> GetAllCountriesAsync();
    Task<List<Country>> GetCountriesByContinentAsync(int continentId);
    Task<Country?> GetCountryByIdAsync(int countryId);
    Task<Country?> GetCountryByCodeAsync(string code);

    // ── Divisions ─────────────────────────────────────────────
    Task<List<AdministrativeDivision>> GetDivisionsByCountryAsync(int countryId);
    Task<List<AdministrativeDivision>> GetChildDivisionsAsync(int parentDivisionId);
    Task<AdministrativeDivision?> GetDivisionByIdAsync(int divisionId);

    // ── Cities ────────────────────────────────────────────────
    Task<PagedResult<City>> GetCitiesAsync(CityFilterDto filter);
    Task<City?> GetCityByIdAsync(int cityId);
    Task<List<City>> GetCitiesByCountryAsync(int countryId);
    Task<List<City>> GetCitiesByDivisionAsync(int divisionId);
    Task<List<City>> SearchCitiesAsync(string searchTerm, int limit = 10);

    // ── Postal Codes ──────────────────────────────────────────
    Task<List<PostalCode>> GetPostalCodesByCityAsync(int cityId);
    Task<PostalCode?> GetPostalCodeByCodeAsync(string code);
}
