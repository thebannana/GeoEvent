using Microsoft.Extensions.Configuration;

namespace EventService.Infrastructure.Services;

public class ServiceAuthHandler : DelegatingHandler
{
    private const string HeaderName = "X-Api-Key";
    private readonly IConfiguration _configuration;

    public ServiceAuthHandler(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var apiKey = _configuration["InternalApi:Key"];

        if (!string.IsNullOrWhiteSpace(apiKey) &&
            !request.Headers.Contains(HeaderName))
        {
            request.Headers.Add(HeaderName, apiKey);
        }

        return base.SendAsync(request, cancellationToken);
    }
}