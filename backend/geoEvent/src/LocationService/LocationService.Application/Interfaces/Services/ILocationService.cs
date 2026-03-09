using LocationService.Application.Common;
using LocationService.Application.DTOs;

namespace LocationService.Application.Interfaces.Services;

public interface ILocationService
{
    // ── Continents ────────────────────────────────────────────
    Task<ServiceResult<List<ContinentResponseDto>>> GetAllContinentsAsync();
    Task<ServiceResult<ContinentResponseDto>> GetContinentByIdAsync(int continentId);

    // ── Countries ─────────────────────────────────────────────
    Task<ServiceResult<List<CountryResponseDto>>> GetAllCountriesAsync();
    Task<ServiceResult<List<CountryResponseDto>>> GetCountriesByContinentAsync(int continentId);
    Task<ServiceResult<CountryResponseDto>> GetCountryByIdAsync(int countryId);

    // ── Divisions ─────────────────────────────────────────────
    Task<ServiceResult<List<DivisionResponseDto>>> GetDivisionsByCountryAsync(int countryId);
    Task<ServiceResult<List<DivisionResponseDto>>> GetChildDivisionsAsync(int parentDivisionId);
    Task<ServiceResult<DivisionResponseDto>> GetDivisionByIdAsync(int divisionId);

    // ── Cities ────────────────────────────────────────────────
    Task<ServiceResult<PagedResult<CityResponseDto>>> GetCitiesAsync(CityFilterDto filter);
    Task<ServiceResult<CityResponseDto>> GetCityByIdAsync(int cityId);
    Task<ServiceResult<List<CityResponseDto>>> GetCitiesByCountryAsync(int countryId);
    Task<ServiceResult<List<CityResponseDto>>> SearchCitiesAsync(string searchTerm, int limit = 10);

    // ── Postal Codes ──────────────────────────────────────────
    Task<ServiceResult<List<PostalCodeResponseDto>>> GetPostalCodesByCityAsync(int cityId);
}
