FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/NotificationService/NotificationService.API/NotificationService.API.csproj --disable-parallel
RUN dotnet publish src/NotificationService/NotificationService.API/NotificationService.API.csproj -c Release -o /app/publish --no-restore --no-self-contained

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "NotificationService.API.dll"]