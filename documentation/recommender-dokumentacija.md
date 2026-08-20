# GeoEvent Recommendation System

## Overview

GeoEvent uses a hybrid recommendation system that combines content-based filtering with context-aware information such as the user's location. The system also considers event popularity, featured status, and search text when ranking events.

The recommendation process uses weighted scoring rules based on data collected from user interactions and event metadata. Each recommendation can therefore be explained through the factors that contributed to its score.

## User preferences

User preferences are stored in the `UserPreferences` table. They are updated when the user interacts with events.

The supported interactions and their backend weights are:

- Like: segment +1, genre +2, subgenre +3.
- Bookmark: segment +2, genre +3, subgenre +4.
- Comment: segment +2, genre +4, subgenre +5.
- Confirmed reservation: segment +3, genre +5, subgenre +7.

These values represent the user's interest in event segments, genres, and subgenres. A confirmed reservation has a higher weight because it represents stronger interest than a simple like.

## Backend recommendation

When a logged-in user enables preference-based results, the backend calculates an event score using the stored preference values.

The backend formula is:

```text
BackendScore = SegmentScore + 2 * GenreScore + 3 * SubGenreScore + 0.5 * Featured
```

`Featured` is 1 for a featured event and 0 otherwise. Events are then ordered by recommendation score, start date, number of likes, and event ID.

If the user has no stored preferences, the system uses the normal event listing instead of personalized ranking.

## Flutter recommendation

The Flutter client also performs local scoring for search results and map events. Its basic preference score is:

```text
PreferenceScore = 30 * SegmentMatch
                + 22 * GenreMatch
                + 16 * SubGenreMatch
                + 6 * Featured
```

Each match value is either 1 or 0. For example, an event in a preferred segment receives 30 points, while an event in a preferred subgenre receives 16 points.

## Location and map scoring

The application obtains the user's GPS location and compares it with the event coordinates. Distance is calculated using the Haversine formula and is expressed in kilometres.

For map recommendations, the score additionally includes distance, likes, views, and a featured bonus:

```text
MapScore = PreferenceScore
         + DistanceScore
         + round(LikesCount / 25)
         + round(ViewCount / 250)
         + 4 * Featured
```

Distance points are assigned as follows:

- Up to 2 km: +24 points.
- More than 2 km and up to 5 km: +16 points.
- More than 5 km and up to 10 km: +10 points.
- More than 10 km and up to 25 km: +4 points.
- More than 25 km: no distance bonus.

Nearby search also uses the user's coordinates and a selected radius to return local events.

## Search scoring

For search cards, the Flutter client uses text matching, preferences, popularity, and location:

```text
SearchScore = TextScore
            + PreferenceScore
            + round(LikesCount / 20)
            + round(ViewCount / 200)
            + LocationAdjustment
```

Text matching gives the following points:

- Title contains the search text: +80 points.
- Segment contains the search text: +30 points.
- Genre contains the search text: +25 points.
- Subgenre contains the search text: +20 points.
- Tags contain the search text: +15 points.

If global events are not selected, an event inside the selected radius receives +20 points and an event outside the radius receives -20 points.

## Featured events

Featured status gives events an additional score. It does not automatically place an event first. An event with a stronger category match, closer location, better text match, or higher popularity can still rank above a featured event.

## Map priorities

The final map score is converted into a priority:

- Score 60 or higher: high priority.
- Score from 35 to 59: medium priority.
- Score below 35: low priority.

At distant zoom levels, the map shows mainly high-priority events to avoid overcrowding. When the user zooms in, medium- and low-priority events become visible.

## Explainability

The recommendation is explainable because the score is based on clear factors:

- Matching user preferences.
- Distance from the user.
- Number of likes and views.
- Featured status.
- Matching search text.

When personalized sorting is active and there is no text query, the interface can show the message `Based on your activity`.

## Summary

GeoEvent uses a hybrid recommendation system that combines content-based user preferences with location-aware ranking. User interactions are stored in the database, events are scored using explicit weighted factors, and the resulting recommendations can be explained using categories, distance, popularity, featured status, and search relevance.