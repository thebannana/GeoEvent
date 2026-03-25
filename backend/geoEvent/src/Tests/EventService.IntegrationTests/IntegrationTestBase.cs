namespace EventService.IntegrationTests;

public abstract class IntegrationTestBase : IAsyncLifetime
{
    protected readonly CustomWebApplicationFactory Factory;

    protected IntegrationTestBase(CustomWebApplicationFactory factory)
    {
        Factory = factory;
    }

    public async Task InitializeAsync()
        => await Factory.ResetDatabaseAsync();

    public Task DisposeAsync() => Task.CompletedTask;
}
