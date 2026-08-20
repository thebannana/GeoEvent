FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["src/SeedGeneration/SeedGenerator/SeedGenerator.csproj", "src/SeedGeneration/SeedGenerator/"]
COPY ["src/UserService/UserService.Infrastructure/UserService.Infrastructure.csproj", "src/UserService/UserService.Infrastructure/"]
COPY ["src/UserService/UserService.Application/UserService.Application.csproj", "src/UserService/UserService.Application/"]
COPY ["src/UserService/UserService.Domain/UserService.Domain.csproj", "src/UserService/UserService.Domain/"]
COPY ["src/EventService/EventService.Infrastructure/EventService.Infrastructure.csproj", "src/EventService/EventService.Infrastructure/"]
COPY ["src/EventService/EventService.Application/EventService.Application.csproj", "src/EventService/EventService.Application/"]
COPY ["src/EventService/EventService.Domain/EventService.Domain.csproj", "src/EventService/EventService.Domain/"]
COPY ["src/MessageService/MessageService.Infrastructure/MessageService.Infrastructure.csproj", "src/MessageService/MessageService.Infrastructure/"]
COPY ["src/MessageService/MessageService.Application/MessageService.Application.csproj", "src/MessageService/MessageService.Application/"]
COPY ["src/MessageService/MessageService.Domain/MessageService.Domain.csproj", "src/MessageService/MessageService.Domain/"]
COPY ["src/NotificationService/NotificationService.Infrastructure/NotificationService.Infrastructure.csproj", "src/NotificationService/NotificationService.Infrastructure/"]
COPY ["src/NotificationService/NotificationService.Application/NotificationService.Application.csproj", "src/NotificationService/NotificationService.Application/"]
COPY ["src/NotificationService/NotificationService.Domain/NotificationService.Domain.csproj", "src/NotificationService/NotificationService.Domain/"]
COPY ["src/TicketService/TicketService.Infrastructure/TicketService.Infrastructure.csproj", "src/TicketService/TicketService.Infrastructure/"]
COPY ["src/TicketService/TicketService.Application/TicketService.Application.csproj", "src/TicketService/TicketService.Application/"]
COPY ["src/TicketService/TicketService.Domain/TicketService.Domain.csproj", "src/TicketService/TicketService.Domain/"]

COPY ["src/Shared.Contracts/Shared.Contracts/Shared.Contracts.csproj", "src/Shared.Contracts/Shared.Contracts/"]

RUN dotnet restore "src/SeedGeneration/SeedGenerator/SeedGenerator.csproj"

COPY . .
WORKDIR "/src/src/SeedGeneration/SeedGenerator"
RUN dotnet build "SeedGenerator.csproj" -c Release -o /app/build --no-restore

FROM build AS publish
RUN dotnet publish "SeedGenerator.csproj" -c Release -o /app/publish /p:UseAppHost=false --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "SeedGenerator.dll", "all"]