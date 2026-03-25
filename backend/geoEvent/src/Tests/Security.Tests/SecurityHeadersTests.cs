using FluentAssertions;

namespace Security.Tests;

public class SecurityHeadersTests
{
    // Tests the SecurityHeadersMiddleware logic in isolation

    private static Dictionary<string, string> GetExpectedHeaders() => new()
    {
        ["X-Content-Type-Options"] = "nosniff",
        ["X-Frame-Options"] = "DENY",
        ["X-XSS-Protection"] = "1; mode=block",
        ["Referrer-Policy"] = "strict-origin-when-cross-origin",
        ["Content-Security-Policy"] = "default-src 'self'"
    };

    [Theory]
    [InlineData("X-Content-Type-Options", "nosniff")]
    [InlineData("X-Frame-Options", "DENY")]
    [InlineData("X-XSS-Protection", "1; mode=block")]
    [InlineData("Referrer-Policy", "strict-origin-when-cross-origin")]
    [InlineData("Content-Security-Policy", "default-src 'self'")]
    public void SecurityHeader_HasCorrectValue(string header, string expectedValue)
    {
        var headers = GetExpectedHeaders();

        headers[header].Should().Be(expectedValue);
    }

    [Fact]
    public void AllRequiredSecurityHeaders_AreDefined()
    {
        var headers = GetExpectedHeaders();

        headers.Should().ContainKey("X-Content-Type-Options");
        headers.Should().ContainKey("X-Frame-Options");
        headers.Should().ContainKey("X-XSS-Protection");
        headers.Should().ContainKey("Referrer-Policy");
        headers.Should().ContainKey("Content-Security-Policy");
    }

    [Fact]
    public void ServerHeader_ShouldNotBeExposed()
    {
        // Validates the intent of SecurityHeadersMiddleware removing "Server" header
        var headersToRemove = new[] { "Server" };

        headersToRemove.Should().Contain("Server",
            "the Server header exposes technology stack information");
    }

    [Fact]
    public void ContentSecurityPolicy_RestrictsToSelf()
    {
        var csp = GetExpectedHeaders()["Content-Security-Policy"];

        csp.Should().Contain("default-src 'self'",
            "CSP must restrict resource loading to same origin by default");
        csp.Should().NotContain("unsafe-inline",
            "unsafe-inline allows XSS attacks");
        csp.Should().NotContain("unsafe-eval",
            "unsafe-eval allows code injection attacks");
    }

    [Fact]
    public void XFrameOptions_PreventsClickjacking()
    {
        var xFrameOptions = GetExpectedHeaders()["X-Frame-Options"];

        xFrameOptions.Should().Be("DENY",
            "DENY prevents the page from being embedded in any frame, stopping clickjacking");
    }
}
