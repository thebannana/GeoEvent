using LocationService.Application.Common;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces.Repositories;
using LocationService.Application.Interfaces.Services;
using LocationService.Domain.Entities;

namespace LocationService.Infrastructure.Services;

public class LocationServiceImpl : ILocationService
{
    private readonly ILocationRepository _repository;

    public LocationServiceImpl(ILocationRepository repository)
    {
        _repository = repository;
    }

    // ── Continents ────────────────────────────────────────────
    public async Task<ServiceResult<List<ContinentResponseDto>>> GetAllContinentsAsync()
    {
        var continents = await _repository.GetAllContinentsAsync();
        return ServiceResult<List<ContinentResponseDto>>.Ok(continents.Select(MapContinent).ToList());
    }

    public async Task<ServiceResult<ContinentResponseDto>> GetContinentByIdAsync(int continentId)
    {
        var continent = await _repository.GetContinentByIdAsync(continentId);
        if (continent is null)
            return ServiceResult<ContinentResponseDto>.NotFound("Continent not found.");
        return ServiceResult<ContinentResponseDto>.Ok(MapContinent(continent));
    }

    // ── Countries ─────────────────────────────────────────────
    public async Task<ServiceResult<List<CountryResponseDto>>> GetAllCountriesAsync()
    {
        var countries = await _repository.GetAllCountriesAsync();
        return ServiceResult<List<CountryResponseDto>>.Ok(countries.Select(MapCountry).ToList());
    }

    public async Task<ServiceResult<List<CountryResponseDto>>> GetCountriesByContinentAsync(int continentId)
    {
        var countries = await _repository.GetCountriesByContinentAsync(continentId);
        return ServiceResult<List<CountryResponseDto>>.Ok(countries.Select(MapCountry).ToList());
    }

    public async Task<ServiceResult<CountryResponseDto>> GetCountryByIdAsync(int countryId)
    {
        var country = await _repository.GetCountryByIdAsync(countryId);
        if (country is null)
            return ServiceResult<CountryResponseDto>.NotFound("Country not found.");
        return ServiceResult<CountryResponseDto>.Ok(MapCountry(country));
    }

    // ── Divisions ─────────────────────────────────────────────
    public async Task<ServiceResult<List<DivisionResponseDto>>> GetDivisionsByCountryAsync(int countryId)
    {
        var divisions = await _repository.GetDivisionsByCountryAsync(countryId);
        return ServiceResult<List<DivisionResponseDto>>.Ok(divisions.Select(MapDivision).ToList());
    }

    public async Task<ServiceResult<List<DivisionResponseDto>>> GetChildDivisionsAsync(int parentDivisionId)
    {
        var divisions = await _repository.GetChildDivisionsAsync(parentDivisionId);
        return ServiceResult<List<DivisionResponseDto>>.Ok(divisions.Select(MapDivision).ToList());
    }

    public async Task<ServiceResult<DivisionResponseDto>> GetDivisionByIdAsync(int divisionId)
    {
        var division = await _repository.GetDivisionByIdAsync(divisionId);
        if (division is null)
            return ServiceResult<DivisionResponseDto>.NotFound("Division not found.");
        return ServiceResult<DivisionResponseDto>.Ok(MapDivision(division));
    }

    // ── Cities ────────────────────────────────────────────────
    public async Task<ServiceResult<PagedResult<CityResponseDto>>> GetCitiesAsync(CityFilterDto filter)
    {
        var result = await _repository.GetCitiesAsync(filter);
        var mapped = new PagedResult<CityResponseDto>
        {
            Items = result.Items.Select(MapCity),
            TotalCount = result.TotalCount,
            Page = result.Page,
            PageSize = result.PageSize
        };
        return ServiceResult<PagedResult<CityResponseDto>>.Ok(mapped);
    }

    public async Task<ServiceResult<CityResponseDto>> GetCityByIdAsync(int cityId)
    {
        var city = await _repository.GetCityByIdAsync(cityId);
        if (city is null)
            return ServiceResult<CityResponseDto>.NotFound("City not found.");
        return ServiceResult<CityResponseDto>.Ok(MapCity(city));
    }

    public async Task<ServiceResult<List<CityResponseDto>>> GetCitiesByCountryAsync(int countryId)
    {
        var cities = await _repository.GetCitiesByCountryAsync(countryId);
        return ServiceResult<List<CityResponseDto>>.Ok(cities.Select(MapCity).ToList());
    }

    public async Task<ServiceResult<List<CityResponseDto>>> SearchCitiesAsync(string searchTerm, int limit = 10)
    {
        var cities = await _repository.SearchCitiesAsync(searchTerm, limit);
        return ServiceResult<List<CityResponseDto>>.Ok(cities.Select(MapCity).ToList());
    }

    // ── Postal Codes ──────────────────────────────────────────
    public async Task<ServiceResult<List<PostalCodeResponseDto>>> GetPostalCodesByCityAsync(int cityId)
    {
        var codes = await _repository.GetPostalCodesByCityAsync(cityId);
        return ServiceResult<List<PostalCodeResponseDto>>.Ok(codes.Select(MapPostalCode).ToList());
    }

    // ── Mappers ───────────────────────────────────────────────
    private static ContinentResponseDto MapContinent(Continent c) => new()
    {
        ContinentId = c.ContinentId,
        ContinentName = c.ContinentName,
        ContinentCode = c.ContinentCode
    };

    private static CountryResponseDto MapCountry(Country c) => new()
    {
        CountryId = c.CountryId,
        CountryName = c.CountryName,
        CountryCodeAlpha2 = c.CountryCodeAlpha2,
        CountryCodeAlpha3 = c.CountryCodeAlpha3,
        CountryCodeNumeric = c.CountryCodeNumeric,
        IsActive = c.IsActive,
        ContinentId = c.ContinentId,
        ContinentName = c.Continent?.ContinentName
    };

    private static DivisionResponseDto MapDivision(AdministrativeDivision d) => new()
    {
        DivisionId = d.DivisionId,
        CountryId = d.CountryId,
        ParentDivisionId = d.ParentDivisionId,
        DivisionName = d.DivisionName,
        DivisionCode = d.DivisionCode,
        DivisionType = d.DivisionType,
        Level = d.Level,
        Latitude = d.Latitude,
        Longitude = d.Longitude,
        IsActive = d.IsActive
    };

    private static CityResponseDto MapCity(City c) => new()
    {
        CityId = c.CityId,
        CityName = c.CityName,
        NormalizedName = c.NormalizedName,
        Longitude = c.Longitude,
        Latitude = c.Latitude,
        DivisionId = c.DivisionId,
        DivisionName = c.Division?.DivisionName,
        CountryId = c.CountryId,
        CountryName = c.Country?.CountryName,
        IsActive = c.IsActive
    };

    private static PostalCodeResponseDto MapPostalCode(PostalCode p) => new()
    {
        PostalCodeId = p.PostalCodeId,
        Code = p.Code,
        Longitude = p.Longitude,
        Latitude = p.Latitude,
        CityId = p.CityId
    };
}
