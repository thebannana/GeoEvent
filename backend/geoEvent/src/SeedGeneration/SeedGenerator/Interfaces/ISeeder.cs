namespace SeedGeneration.SeedGenerator.Interfaces;

public interface ISeeder
{
    string Name { get; }
    Task SeedAsync(CancellationToken cancellationToken = default);
}