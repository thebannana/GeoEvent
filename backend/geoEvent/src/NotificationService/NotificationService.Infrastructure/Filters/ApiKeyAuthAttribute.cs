using Microsoft.AspNetCore.Mvc;

namespace NotificationService.Infrastructure.Filters;

public class ApiKeyAuthAttribute : ServiceFilterAttribute
{
    public ApiKeyAuthAttribute() : base(typeof(ApiKeyAuthFilter)) { }
}