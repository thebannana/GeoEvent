# GeoEvent

GeoEvent is a microservices-based event management and ticketing platform. Users can discover events, search by category and location, view event details, like and bookmark events, comment, reserve tickets, use chat, and receive notifications. Administrators use the Windows desktop application to manage users, events, reports, reservations, and other administrative data.

## Technologies

- Backend: C#, .NET 9, ASP.NET Core Web API, Entity Framework Core.
- Database: Microsoft SQL Server.
- Messaging: RabbitMQ and MassTransit.
- Clients: Flutter mobile application and Flutter Windows desktop application.
- Maps and location: Mapbox and GPS.
- Payments: PayPal Sandbox.
- Deployment: Docker and Docker Compose.
- Authentication: JWT access tokens and refresh tokens.

## Recommendation system

GeoEvent uses a hybrid recommendation system based on user preferences, event categories, location, popularity, featured status, and search text. Likes, bookmarks, comments, and confirmed reservations contribute to stored user preferences for segments, genres, and subgenres. GPS location is used for nearby-event filtering and distance-based ranking. Likes, views, and featured status also influence the final score.

The recommendation system is explained in:

```text
documentation/recommender-dokumentacija.md
```

The document contains the scoring rules, the role of location, the effect of featured events, and the map pin priorities.

## Running the project

Requirements:

- Docker Desktop.
- Flutter SDK.
- Android Studio and an Android emulator for the mobile application.
- Visual Studio with Windows desktop development tools for the desktop application.

Create the required `.env` file in the backend directory. It must contain the database, RabbitMQ, JWT, PayPal, SMTP, image storage, and service URL configuration. Do not commit the `.env` file to GitHub.

Start the backend from the directory containing `docker-compose.yml`:

```powershell
docker compose up --build -d
```

Check the services:

```powershell
docker compose ps
```

Stop the services:

```powershell
docker compose down
```

For a complete local database reset:

```powershell
docker compose down --volumes
docker compose up --build -d
```

## Test accounts

### Administrator

```text
Username: dengabenga
Email: kundodenis@gmail.com
Password: Admin123!
```

This account can be used to test administration, event management, reports, users, reservations, and refund management.

### Regular users

```text
Username: johndoe
Email: john.doe@geoevent.local
Password: User123!
```

```text
Username: janesmith
Email: jane.smith@geoevent.local
Password: User123!
```

```text
Username: markohorvat
Email: marko.horvat@geoevent.local
Password: User123!
```

```text
Username: anaperic
Email: ana.peric@geoevent.local
Password: User123!
```

```text
Username: lukajovanovic
Email: luka.jovanovic@geoevent.local
Password: User123!
```

The seed process creates sample segments, genres, subgenres, preferences, events, event images, likes, bookmarks, comments, reports, chat data, and notifications. These profiles and records provide data for testing event browsing, recommendations, filtering, maps, administration, and communication features.

## Mobile and desktop builds

Android APK:

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Windows desktop:

```powershell
flutter clean
flutter pub get
flutter build windows --release --dart-define=API_BASE_URL=http://localhost:5000
```

## Payment testing

PayPal payments must be tested through the PayPal Sandbox using valid Sandbox credentials and a Sandbox buyer account. Payment records are not created as successful seed data because payment confirmation must be verified through the PayPal Sandbox flow. Refund functionality can be tested after a successful Sandbox payment.
