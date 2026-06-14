using System.Net.Http.Headers;
using Microsoft.Extensions.Configuration;

namespace EventService.Infrastructure.Services;

public class ServiceAuthHandler : DelegatingHandler
{
    private readonly IConfiguration _configuration;

    public ServiceAuthHandler(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var token = _configuration["ServiceAuth:UserServiceToken"];

        if (!string.IsNullOrWhiteSpace(token))
        {
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", token);
        }

        return base.SendAsync(request, cancellationToken);
    }
}