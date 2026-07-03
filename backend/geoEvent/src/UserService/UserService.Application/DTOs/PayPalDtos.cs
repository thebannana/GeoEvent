namespace UserService.Application.DTOs;

public class PayPalStatusDto
{
    public bool Enabled { get; set; }
    public string Mode { get; set; } = "sandbox";
    public bool CredentialsConfigured { get; set; }
}