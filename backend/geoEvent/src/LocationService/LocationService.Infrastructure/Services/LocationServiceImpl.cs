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
        return ServiceResult<List<ContinentResponseDto>>.Ok(
            continents.Select(MapContinent).ToList());
    }

    public async Task<ServiceResult<ContinentResponseDto>> GetContinentByIdAsync(int continentId)
    {
        var continent = await _repository.GetContinentByIdAsync(continentId);
        if (continent is null)
            return ServiceResult<ContinentResponseDto>.NotFound("Continent not found.");
        return ServiceResult<ContinentResponseDto>.Ok(MapContinent(continent));
    }


    // ── Countries ─────────────────────────────────────────────
    public async Task<ServiceResult<List<CountryResponseDto>>> GetCountriesAsync(
        CountryFilterDto filter)
    {
        var countries = await _repository.GetCountriesAsync(filter);
        return ServiceResult<List<CountryResponseDto>>.Ok(
            countries.Select(MapCountry).ToList());
    }

    public async Task<ServiceResult<List<CountryResponseDto>>> GetCountriesByContinentAsync(
    int continentId)
    {
        var countries = await _repository.GetCountriesByContinentAsync(continentId);
        return ServiceResult<List<CountryResponseDto>>.Ok(
            countries.Select(MapCountry).ToList());
    }

    public async Task<ServiceResult<CountryResponseDto>> GetCountryByCodeAsync(string code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return ServiceResult<CountryResponseDto>.Fail("Country code is required.");

        var country = await _repository.GetCountryByCodeAsync(code.Trim());
        if (country is null)
            return ServiceResult<CountryResponseDto>.NotFound(
                $"Country with code '{code}' was not found.");

        return ServiceResult<CountryResponseDto>.Ok(MapCountry(country));
    }


    public async Task<ServiceResult<CountryResponseDto>> GetCountryByIdAsync(int countryId)
    {
        var country = await _repository.GetCountryByIdAsync(countryId);
        if (country is null)
            return ServiceResult<CountryResponseDto>.NotFound("Country not found.");
        return ServiceResult<CountryResponseDto>.Ok(MapCountry(country));
    }

    // ── Divisions ─────────────────────────────────────────────
    public async Task<ServiceResult<List<DivisionResponseDto>>> GetDivisionsAsync(
        DivisionFilterDto filter)
    {
        var divisions = await _repository.GetDivisionsAsync(filter);
        return ServiceResult<List<DivisionResponseDto>>.Ok(
            divisions.Select(MapDivision).ToList());
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

    public async Task<ServiceResult<List<CityResponseDto>>> SearchCitiesAsync(string searchTerm, int limit = 10)
    {
        var cities = await _repository.SearchCitiesAsync(searchTerm, limit);
        return ServiceResult<List<CityResponseDto>>.Ok(cities.Select(MapCity).ToList());
    }

    public async Task<ServiceResult<List<CityResponseDto>>> GetNearbyCitiesAsync(
    NearbySearchDto dto)
    {
        if (dto.RadiusKm <= 0 || dto.RadiusKm > 500)
            return ServiceResult<List<CityResponseDto>>.Fail(
                "Radius must be between 1 and 500 km.");

        if (dto.Limit <= 0 || dto.Limit > 50)
            return ServiceResult<List<CityResponseDto>>.Fail(
                "Limit must be between 1 and 50.");

        var cities = await _repository.GetNearbyCitiesAsync(
            dto.Latitude, dto.Longitude, dto.RadiusKm, dto.Limit);

        return ServiceResult<List<CityResponseDto>>.Ok(
            cities.Select(MapCity).ToList());
    }

    public async Task<ServiceResult<List<CityResponseDto>>> GetCitiesByCountryAsync(int countryId)
    {
        var cities = await _repository.GetCitiesByCountryAsync(countryId);
        return ServiceResult<List<CityResponseDto>>.Ok(cities.Select(MapCity).ToList());
    }

    public async Task<ServiceResult<List<CityResponseDto>>> GetCitiesByDivisionAsync(int divisionId)
    {
        var cities = await _repository.GetCitiesByDivisionAsync(divisionId);
        return ServiceResult<List<CityResponseDto>>.Ok(cities.Select(MapCity).ToList());
    }



    // ── Postal Codes ──────────────────────────────────────────
    public async Task<ServiceResult<List<PostalCodeResponseDto>>> GetPostalCodesByCityAsync(int cityId)
    {
        var codes = await _repository.GetPostalCodesByCityAsync(cityId);
        return ServiceResult<List<PostalCodeResponseDto>>.Ok(codes.Select(MapPostalCode).ToList());
    }

    public async Task<ServiceResult<PostalCodeResponseDto>> GetPostalCodeByCodeAsync(string code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return ServiceResult<PostalCodeResponseDto>.Fail("Postal code is required.");

        var postal = await _repository.GetPostalCodeByCodeAsync(code.Trim());
        if (postal is null)
            return ServiceResult<PostalCodeResponseDto>.NotFound(
                $"Postal code '{code}' was not found.");

        return ServiceResult<PostalCodeResponseDto>.Ok(MapPostalCode(postal));
    }

    public async Task<ServiceResult<PostalCodeResponseDto>> GetPostalCodeByIdAsync(
        int postalCodeId)
    {
        var postal = await _repository.GetPostalCodeByIdAsync(postalCodeId);
        if (postal is null)
            return ServiceResult<PostalCodeResponseDto>.NotFound(
                $"Postal code with ID {postalCodeId} was not found.");

        return ServiceResult<PostalCodeResponseDto>.Ok(MapPostalCode(postal));
    }


    // ── Mappers ───────────────────────────────────────────────

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

    private static ContinentResponseDto MapContinent(Continent c) => new()
    {
        ContinentId = c.ContinentId,
        ContinentName = c.ContinentName,
        ContinentCode = c.ContinentCode,
        CountryCount = c.Countries.Count        // requires Include(Countries) on query
    };

    private static DivisionResponseDto MapDivision(AdministrativeDivision d) => new()
    {
        DivisionId = d.DivisionId,
        CountryId = d.CountryId,
        CountryName = d.Country?.CountryName,
        ParentDivisionId = d.ParentDivisionId,
        ParentDivisionName = d.ParentDivision?.DivisionName,
        DivisionName = d.DivisionName,
        DivisionCode = d.DivisionCode,
        DivisionType = d.DivisionType,
        Level = d.Level,
        Latitude = d.Latitude,
        Longitude = d.Longitude,
        IsActive = d.IsActive,
        ChildCount = d.ChildDivisions.Count
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
        DivisionType = c.Division?.DivisionType,
        CountryId = c.Division?.CountryId,              // resolve via Division
        CountryName = c.Division?.Country?.CountryName,
        IsActive = c.IsActive,
        PostalCodes = c.PostalCodes.Select(MapPostalCode).ToList()
    };

    private static PostalCodeResponseDto MapPostalCode(PostalCode p) => new()
    {
        PostalCodeId = p.PostalCodeId,
        Code = p.Code,
        Longitude = p.Longitude,
        Latitude = p.Latitude,
        CityId = p.CityId,
        CityName = p.City?.CityName
    };

}
