namespace UserService.Infrastructure.Options;

public class PayPalOptions
{
    public string Mode { get; set; } = "sandbox";
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;

    public string BaseUrl =>
        Mode.Equals("live", StringComparison.OrdinalIgnoreCase)
            ? "https://api-m.paypal.com"
            : "https://api-m.sandbox.paypal.com";
}