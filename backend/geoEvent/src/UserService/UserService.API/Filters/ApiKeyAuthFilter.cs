using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace UserService.API.Filters;

public sealed class InternalApiKeyAuthFilter : IAsyncActionFilter
{
    private const string HeaderName = "X-Api-Key";
    private readonly IConfiguration _configuration;
    private readonly ILogger<InternalApiKeyAuthFilter> _logger;

    public InternalApiKeyAuthFilter(
        IConfiguration configuration,
        ILogger<InternalApiKeyAuthFilter> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var expectedApiKey = _configuration["InternalApi:Key"];

        if (string.IsNullOrWhiteSpace(expectedApiKey))
        {
            _logger.LogError("Internal API key is missing from configuration.");
            context.Result = new StatusCodeResult(StatusCodes.Status500InternalServerError);
            return;
        }

        if (!context.HttpContext.Request.Headers.TryGetValue(HeaderName, out var providedApiKeyValues))
        {
            _logger.LogWarning(
                "Missing internal API key header for path {Path}",
                context.HttpContext.Request.Path);

            context.Result = new UnauthorizedObjectResult(new
            {
                error = "Invalid internal API key."
            });
            return;
        }

        var providedApiKey = providedApiKeyValues.ToString();
        if (string.IsNullOrWhiteSpace(providedApiKey))
        {
            _logger.LogWarning(
                "Empty internal API key header for path {Path}",
                context.HttpContext.Request.Path);

            context.Result = new UnauthorizedObjectResult(new
            {
                error = "Invalid internal API key."
            });
            return;
        }

        var expectedBytes = Encoding.UTF8.GetBytes(expectedApiKey);
        var providedBytes = Encoding.UTF8.GetBytes(providedApiKey);

        var isValid =
            expectedBytes.Length == providedBytes.Length &&
            CryptographicOperations.FixedTimeEquals(expectedBytes, providedBytes);

        if (!isValid)
        {
            _logger.LogWarning(
                "Invalid internal API key for path {Path}",
                context.HttpContext.Request.Path);

            context.Result = new UnauthorizedObjectResult(new
            {
                error = "Invalid internal API key."
            });
            return;
        }

        await next();
    }
}