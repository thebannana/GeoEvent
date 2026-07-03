FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
ENV DOTNET_ENVIRONMENT=Production

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/Workers/HelperWorkers/HelperWorkers.csproj --disable-parallel
RUN dotnet publish src/Workers/HelperWorkers/HelperWorkers.csproj -c Release -o /app/publish --no-restore --no-self-contained
RUN ls -la /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish/ .
ENTRYPOINT ["dotnet", "NotificationService.Worker.dll"]