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
    public async Task<List<Country>> GetAllCountriesAsync() =>
        await _context.Countries
            .Include(c => c.Continent)
            .Where(c => c.IsActive)
            .OrderBy(c => c.CountryName)
            .ToListAsync();

    public async Task<List<Country>> GetCountriesByContinentAsync(int continentId) =>
        await _context.Countries
            .Include(c => c.Continent)
            .Where(c => c.ContinentId == continentId && c.IsActive)
            .OrderBy(c => c.CountryName)
            .ToListAsync();

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
    public async Task<List<AdministrativeDivision>> GetDivisionsByCountryAsync(int countryId) =>
        await _context.AdministrativeDivisions
            .Where(d => d.CountryId == countryId && d.IsActive)
            .OrderBy(d => d.Level)
            .ThenBy(d => d.DivisionName)
            .ToListAsync();

    public async Task<List<AdministrativeDivision>> GetChildDivisionsAsync(int parentDivisionId) =>
        await _context.AdministrativeDivisions
            .Where(d => d.ParentDivisionId == parentDivisionId && d.IsActive)
            .OrderBy(d => d.DivisionName)
            .ToListAsync();

    public async Task<AdministrativeDivision?> GetDivisionByIdAsync(int divisionId) =>
        await _context.AdministrativeDivisions
            .Include(d => d.Country)
            .Include(d => d.ParentDivision)
            .FirstOrDefaultAsync(d => d.DivisionId == divisionId);

    // ── Cities ────────────────────────────────────────────────
    public async Task<PagedResult<City>> GetCitiesAsync(CityFilterDto filter)
    {
        var query = _context.Cities
            .Include(c => c.Country)
            .Include(c => c.Division)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filter.SearchTerm))
            query = query.Where(c => c.NormalizedName.Contains(filter.SearchTerm.ToLower()) ||
                                     c.CityName.Contains(filter.SearchTerm));

        if (filter.CountryId.HasValue)
            query = query.Where(c => c.CountryId == filter.CountryId);

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

    public async Task<City?> GetCityByIdAsync(int cityId) =>
        await _context.Cities
            .Include(c => c.Country)
            .Include(c => c.Division)
            .FirstOrDefaultAsync(c => c.CityId == cityId);

    public async Task<List<City>> GetCitiesByCountryAsync(int countryId) =>
        await _context.Cities
            .Where(c => c.CountryId == countryId && c.IsActive)
            .OrderBy(c => c.CityName)
            .ToListAsync();

    public async Task<List<City>> GetCitiesByDivisionAsync(int divisionId) =>
        await _context.Cities
            .Where(c => c.DivisionId == divisionId && c.IsActive)
            .OrderBy(c => c.CityName)
            .ToListAsync();

    public async Task<List<City>> SearchCitiesAsync(string searchTerm, int limit = 10) =>
        await _context.Cities
            .Include(c => c.Country)
            .Where(c => c.IsActive &&
                       (c.NormalizedName.Contains(searchTerm.ToLower()) ||
                        c.CityName.Contains(searchTerm)))
            .OrderBy(c => c.CityName)
            .Take(limit)
            .ToListAsync();

    // ── Postal Codes ──────────────────────────────────────────
    public async Task<List<PostalCode>> GetPostalCodesByCityAsync(int cityId) =>
        await _context.PostalCodes
            .Where(p => p.CityId == cityId)
            .OrderBy(p => p.Code)
            .ToListAsync();

    public async Task<PostalCode?> GetPostalCodeByCodeAsync(string code) =>
        await _context.PostalCodes
            .Include(p => p.City)
            .FirstOrDefaultAsync(p => p.Code == code);
}
