FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app
ENV DOTNET_ENVIRONMENT=Production

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/HelperWorkers/GeoEvent.HelperWorkers/GeoEvent.HelperWorkers.csproj --disable-parallel
RUN dotnet publish src/HelperWorkers/GeoEvent.HelperWorkers/GeoEvent.HelperWorkers.csproj -c Release -o /app/publish --no-restore --no-self-contained

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "GeoEvent.HelperWorkers.dll"]