using Microsoft.EntityFrameworkCore;
using LocationService.Application.Common;
using LocationService.Application.DTOs;
using LocationService.Application.Interfaces.Repositories;
using LocationService.Domain.Entities;
using LocationService.Infrastructure.Persistence;

namespace LocationService.Infrastructure.Repositories;

public class LocationRepository : ILocationRepository
{
    private readonly LocationDbContext _context;

    public LocationRepository(LocationDbContext context)
    {
        _context = context;
    }

    // ── Continents ────────────────────────────────────────────
    public async Task<List<Continent>> GetAllContinentsAsync() =>
        await _context.Continents
            .OrderBy(c => c.ContinentName)
            .ToListAsync();

    public async Task<Continent?> GetContinentByIdAsync(int continentId) =>
        await _context.Continents
            .FirstOrDefaultAsync(c => c.ContinentId == continentId);

    // ── Countries ─────────────────────────────────────────────

    public async Task<List<Country>> GetCountriesByContinentAsync(int continentId) =>
        await _context.Countries
            .Include(c => c.Continent)
            .Where(c => c.ContinentId == continentId && c.IsActive)
            .OrderBy(c => c.CountryName)
            .ToListAsync();

    public async Task<List<Country>> GetCountriesAsync(CountryFilterDto filter)
    {
        var query = _context.Countries
            .Include(c => c.Continent)
            .AsQueryable();

        if (filter.ContinentId.HasValue)
            query = query.Where(c => c.ContinentId == filter.ContinentId);

        if (filter.IsActive.HasValue)
            query = query.Where(c => c.IsActive == filter.IsActive);

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.ToLower();
            query = query.Where(c => c.CountryName.ToLower().Contains(term));
        }

        return await query.OrderBy(c => c.CountryName).ToListAsync();
    }


    public async Task<Country?> GetCountryByIdAsync(int countryId) =>
        await _context.Countries
            .Include(c => c.Continent)
            .FirstOrDefaultAsync(c => c.CountryId == countryId);

    public async Task<Country?> GetCountryByCodeAsync(string code) =>
        await _context.Countries
            .Include(c => c.Continent)
            .FirstOrDefaultAsync(c =>
                c.CountryCodeAlpha2 == code.ToUpper() ||
                c.CountryCodeAlpha3 == code.ToUpper());

    // ── Divisions ─────────────────────────────────────────────

    public async Task<List<AdministrativeDivision>> GetDivisionsAsync(DivisionFilterDto filter)
    {
        var query = _context.AdministrativeDivisions
            .Include(d => d.Country)
            .Include(d => d.ParentDivision)
            .Include(d => d.ChildDivisions)
            .AsQueryable();

        if (filter.CountryId.HasValue)
            query = query.Where(d => d.CountryId == filter.CountryId);

        if (filter.ParentDivisionId.HasValue)
            query = query.Where(d => d.ParentDivisionId == filter.ParentDivisionId);

        if (filter.Level.HasValue)
            query = query.Where(d => d.Level == filter.Level);

        if (filter.IsActive.HasValue)
            query = query.Where(d => d.IsActive == filter.IsActive);

        if (!string.IsNullOrWhiteSpace(filter.DivisionType))
            query = query.Where(d => d.DivisionType == filter.DivisionType);

        return await query
            .OrderBy(d => d.Level)
            .ThenBy(d => d.DivisionName)
            .ToListAsync();
    }

    public async Task<AdministrativeDivision?> GetDivisionByIdAsync(int divisionId) =>
        await _context.AdministrativeDivisions
            .Include(d => d.Country)
            .Include(d => d.ParentDivision)
            .FirstOrDefaultAsync(d => d.DivisionId == divisionId);

    // ── Cities ────────────────────────────────────────────────
    public async Task<PagedResult<City>> GetCitiesAsync(CityFilterDto filter)
    {
        var query = _context.Cities
            .Include(c => c.Division)
                .ThenInclude(d => d!.Country)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
        {
            var term = filter.SearchTerm.ToLower();
            query = query.Where(c =>
                c.NormalizedName.Contains(term) ||
                c.CityName.ToLower().Contains(term));
        }

        if (filter.DivisionId.HasValue)
            query = query.Where(c => c.DivisionId == filter.DivisionId);

        if (filter.IsActive.HasValue)
            query = query.Where(c => c.IsActive == filter.IsActive);

        query = query.OrderBy(c => c.CityName);

        var total = await query.CountAsync();
        var items = await query
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .ToListAsync();

        return new PagedResult<City>
        {
            Items = items,
            TotalCount = total,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<List<City>> GetNearbyCitiesAsync(
    decimal latitude, decimal longitude, double radiusKm, int limit)
    {
        // Pull candidates within a bounding box first for DB efficiency,
        // then filter precisely in memory using Haversine
        var degreeBuffer = (decimal)(radiusKm / 111.0);

        var candidates = await _context.Cities
            .Include(c => c.Division)
                .ThenInclude(d => d!.Country)
            .Where(c => c.IsActive &&
                c.Latitude >= latitude - degreeBuffer &&
                c.Latitude <= latitude + degreeBuffer &&
                c.Longitude >= longitude - degreeBuffer &&
                c.Longitude <= longitude + degreeBuffer)
            .ToListAsync();

        return candidates
            .Where(c => c.DistanceTo(latitude, longitude) <= radiusKm)
            .OrderBy(c => c.DistanceTo(latitude, longitude))
            .Take(limit)
            .ToList();
    }

    public async Task<City?> GetCityByIdAsync(int cityId) =>
    await _context.Cities
        .Include(c => c.Division)
            .ThenInclude(d => d!.Country)
        .Include(c => c.PostalCodes)
        .FirstOrDefaultAsync(c => c.CityId == cityId);


    public async Task<List<City>> GetCitiesByDivisionAsync(int divisionId) =>
        await _context.Cities
            .Where(c => c.DivisionId == divisionId && c.IsActive)
            .OrderBy(c => c.CityName)
            .ToListAsync();

    public async Task<List<City>> SearchCitiesAsync(string searchTerm, int limit = 10)
    {
        var term = searchTerm.ToLower();
        return await _context.Cities
            .Include(c => c.Division)
                .ThenInclude(d => d!.Country)
            .Where(c => c.IsActive &&
                (c.NormalizedName.Contains(term) ||
                 c.CityName.ToLower().Contains(term)))
            .OrderBy(c => c.CityName)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<City>> GetCitiesByCountryAsync(int countryId) =>
    await _context.Cities
        .Include(c => c.Division)
            .ThenInclude(d => d!.Country)
        .Where(c => c.Division != null &&
                    c.Division.CountryId == countryId &&
                    c.IsActive)
        .OrderBy(c => c.CityName)
        .ToListAsync();



    // ── Postal Codes ──────────────────────────────────────────
    public async Task<List<PostalCode>> GetPostalCodesByCityAsync(int cityId) =>
        await _context.PostalCodes
            .Include(p => p.City)
            .Where(p => p.CityId == cityId)
            .OrderBy(p => p.Code)
            .ToListAsync();

    public async Task<PostalCode?> GetPostalCodeByCodeAsync(string code) =>
        await _context.PostalCodes
            .Include(p => p.City)
            .FirstOrDefaultAsync(p => p.Code == code);

    public async Task<PostalCode?> GetPostalCodeByIdAsync(int postalCodeId) =>
    await _context.PostalCodes
        .Include(p => p.City)
        .FirstOrDefaultAsync(p => p.PostalCodeId == postalCodeId);

}
