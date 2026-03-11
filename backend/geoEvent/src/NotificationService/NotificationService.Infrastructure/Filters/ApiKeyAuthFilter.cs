using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

namespace NotificationService.Infrastructure.Filters;

public class ApiKeyAuthFilter : IAuthorizationFilter
{
    private readonly IConfiguration _config;

    public ApiKeyAuthFilter(IConfiguration config)
    {
        _config = config;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        if (!context.HttpContext.Request.Headers
                .TryGetValue("X-Api-Key", out var key) ||
            key != _config["InternalApi:Key"])
        {
            context.Result = new UnauthorizedResult();
        }
    }
}