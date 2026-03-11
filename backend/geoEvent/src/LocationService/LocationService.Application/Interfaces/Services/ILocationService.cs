using LocationService.Application.Common;
using LocationService.Application.DTOs;

namespace LocationService.Application.Interfaces.Services;

public interface ILocationService
{
    // ── Continents ────────────────────────────────────────────
    Task<ServiceResult<List<ContinentResponseDto>>> GetAllContinentsAsync();
    Task<ServiceResult<ContinentResponseDto>> GetContinentByIdAsync(int continentId);

    // ── Countries ─────────────────────────────────────────────
    Task<ServiceResult<List<CountryResponseDto>>> GetCountriesAsync(CountryFilterDto filter);  // use filter
    Task<ServiceResult<List<CountryResponseDto>>> GetCountriesByContinentAsync(int continentId);
    Task<ServiceResult<CountryResponseDto>> GetCountryByIdAsync(int countryId);
    Task<ServiceResult<CountryResponseDto>> GetCountryByCodeAsync(string code);               // missing — useful for frontend lookups

    // ── Divisions ─────────────────────────────────────────────
    Task<ServiceResult<List<DivisionResponseDto>>> GetDivisionsAsync(DivisionFilterDto filter); // use filter
    Task<ServiceResult<DivisionResponseDto>> GetDivisionByIdAsync(int divisionId);

    // ── Cities ────────────────────────────────────────────────
    Task<ServiceResult<PagedResult<CityResponseDto>>> GetCitiesAsync(CityFilterDto filter);
    Task<ServiceResult<CityResponseDto>> GetCityByIdAsync(int cityId);
    Task<ServiceResult<List<CityResponseDto>>> SearchCitiesAsync(string searchTerm, int limit = 10);
    Task<ServiceResult<List<CityResponseDto>>> GetNearbyCitiesAsync(NearbySearchDto dto);     // new
    Task<ServiceResult<List<CityResponseDto>>> GetCitiesByCountryAsync(int countryId);
    Task<ServiceResult<List<CityResponseDto>>> GetCitiesByDivisionAsync(int divisionId);

    // ── Postal Codes ──────────────────────────────────────────
    Task<ServiceResult<List<PostalCodeResponseDto>>> GetPostalCodesByCityAsync(int cityId);
    Task<ServiceResult<PostalCodeResponseDto>> GetPostalCodeByCodeAsync(string code);         // missing
    Task<ServiceResult<PostalCodeResponseDto>> GetPostalCodeByIdAsync(int postalCodeId);      // missing
}
