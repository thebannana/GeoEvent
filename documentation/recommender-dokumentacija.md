# GeoEvent Recommendation System

## Overview

GeoEvent uses a backend-controlled hybrid recommendation system. It combines content-based preference matching with context-aware signals such as the user's location, event popularity, featured status, and search text.

The backend is the single source of truth for recommendation ranking. Flutter does not calculate a second recommendation score. It displays events in the order returned by the backend and uses the returned `recommendationScore` for map-pin sizing.

Every recommendation can be explained through the factors that contributed to its score.

## User preferences

User preferences are stored in the `UserPreferences` table and updated from user interactions with events.

The supported interactions and their preference increments are:

- Like: segment +1, genre +2, subgenre +3.
- Bookmark: segment +2, genre +3, subgenre +4.
- Comment: segment +2, genre +4, subgenre +5.
- Confirmed reservation: segment +3, genre +5, subgenre +7.

These values represent accumulated interest in event segments, genres, and subgenres. A confirmed reservation receives the strongest increment because it represents stronger intent than a like, bookmark, or comment.

Preference records preserve their hierarchy. A specific genre or subgenre preference includes its parent segment and genre IDs, allowing the backend to match the complete event taxonomy correctly.

## Backend scoring

When a logged-in user enables preference-based results, the backend loads that user's preferences and calculates a score for every filtered candidate before sorting and pagination.

The preference component is:

```text
PreferenceScore = sum(
    PreferenceValue * SpecificityMultiplier
)
```

The specificity multiplier is:

- Segment-only preference: ×1.
- Segment + genre preference: ×2.
- Segment + genre + subgenre preference: ×3.

For example:

```text
Music = 12
Concert = 21
Pop = 16

Music/Concert/Pop preference score
= 12 × 1 + 21 × 2 + 16 × 3
= 102
```

The complete backend score is:

```text
RecommendationScore = PreferenceScore
                    + DistanceScore
                    + PopularityScore
                    + FeaturedScore
                    + TextScore
```

The backend sorts by:

1. Recommendation score descending.
2. Event start date ascending.
3. Likes descending.
4. Event ID ascending.

The backend calculates scores before applying pagination for public search. For nearby results, it calculates scores before applying the requested result limit.

If preference matching is disabled, the backend does not add preference points, but it can still use distance, popularity, featured status, and text relevance according to the endpoint and request.

## Distance scoring

The application obtains the user's GPS coordinates and compares them with each event's coordinates. Distance is calculated using the Haversine formula and expressed in kilometres.

The phone location affects:

- Which events qualify for a nearby request.
- The distance component of the recommendation score.
- The final order when events have similar preference scores.

The backend uses a smooth distance score with a maximum of 8 points:

```text
DistanceScore = 0                         if location is unavailable
DistanceScore = 8                         if distance is 2 km or less
DistanceScore = 8 × (1 - distance/radius) if distance is inside the radius
DistanceScore = 0                         if distance reaches the radius
```

The nearby endpoint first uses a geographic bounding box to find possible candidates, then calculates the exact Haversine distance for scoring.

For example, moving the phone closer to one event can increase that event's score, but distance is intentionally weaker than a strong preference match.

## Popularity scoring

Popularity uses likes and views. Likes have more influence than views, and the combined result is capped so popular events do not permanently overwhelm personal relevance.

```text
LikesScore = ln(1 + LikesCount) × 1.5
ViewsScore = ln(1 + ViewCount) × 0.5
PopularityScore = min(LikesScore + ViewsScore, 12)
```

The logarithmic calculation prevents a very large view count from dominating the recommendation system. It also ensures that popularity still contributes meaningfully for smaller events.

## Featured events

A featured event receives:

```text
FeaturedScore = 4
```

A non-featured event receives:

```text
FeaturedScore = 0
```

Featured status improves visibility but does not automatically place an event first. A strongly preferred or much closer event can still rank above a featured event.

## Search scoring

Search text is applied by the backend after candidate filtering. The text component is added only when a search term is present.

Current text weights are:

- Title contains the search term: +90.
- Description contains the search term: +30.
- Tags contain the search term: +18.

The text component is capped at 90 points.

The backend then combines text relevance with preference, distance, popularity, and featured status:

```text
SearchRecommendationScore = TextScore
                           + PreferenceScore
                           + DistanceScore
                           + PopularityScore
                           + FeaturedScore
```

Search filters such as segment, genre, subgenre, price, date, and featured status are applied before scoring.

## Nearby and global results

### Nearby results

The nearby endpoint receives:

- Latitude.
- Longitude.
- Radius.
- Category filters.
- Price filters.
- Today-only selection.
- Preference-ranking selection.

It filters candidates, calculates their exact distance and recommendation score, sorts them, and then returns the requested limit.

### Global search

Global public search applies the regular event filters first. When preference ranking is enabled, the backend loads all matching candidates, scores them, sorts them, and only then applies page pagination.

Therefore, the first page represents the best results from the complete filtered candidate set rather than the best results from only the first database page.

## Flutter responsibilities

Flutter does not calculate recommendation scores.

Flutter:

- Sends filter values and `usePreferences` to the backend.
- Sends device coordinates for location-aware requests.
- Parses `recommendationScore` from each event response.
- Displays results in the order returned by the backend.
- Displays the calculated distance as informational text.
- Uses the backend score to size map pins.

Flutter must not call a second scorer such as:

```dart
RecommendationScorer.score(...)
rankSearchResults(...)
rankByPreferences(...)
mapRecommendationScore(...)
```

Using a second scorer would cause search and map results to disagree with the backend.

## Map pin sizes

Each API event contains:

```json
{
  "recommendationScore": 102.35
}
```

The frontend converts that score into a Mapbox icon size. The pin service does not recalculate preferences, distance, likes, views, or featured status.

The current size range is approximately:

```text
Score 0   → icon size 0.95
Score 140 → icon size 1.75
```

Scores above 140 are clamped to the maximum visual size. This affects only visual presentation; it does not change ranking.

Map visibility may still be reduced at distant zoom levels to avoid overcrowding, but the backend order and score remain unchanged.

## Example

With these preferences:

```text
Music = 12
Sports = 3
Concert = 21
Football = 5
Pop = 16
Rock = 12
Premier League = 6
```

The preference components are:

```text
Music/Concert/Pop
= 12 × 1 + 21 × 2 + 16 × 3
= 102

Music/Concert/Rock
= 12 × 1 + 21 × 2 + 12 × 3
= 90

Sports/Football/Premier League
= 3 × 1 + 5 × 2 + 6 × 3
= 31
```

The final scores then add distance, popularity, featured status, and optional text relevance. Therefore, Pop should normally rank above Rock, and Rock should normally rank above Premier League, unless search text or another explicit scoring signal changes the result.

## Explainability

The recommendation is explainable because the backend score consists of clear, inspectable components:

- Matching user preferences.
- Distance from the user's phone.
- Likes and views.
- Featured status.
- Search-text relevance.

For debugging, the backend can log each component per event:

```text
EventId=2
Preference=102.00
Distance=7.45
Popularity=1.69
Featured=0.00
Text=0.00
Total=111.14
```

This makes it possible to explain why one event ranked above another.

## Summary

GeoEvent uses one backend recommendation system for public search and nearby map results. User interactions update weighted preferences, the backend scores all filtered candidates, and pagination or result limits are applied only after ranking.

The final score combines:

```text
PreferenceScore
+ DistanceScore
+ PopularityScore
+ FeaturedScore
+ TextScore
```

Flutter only sends request data, displays backend ordering, parses the backend score, and uses that score for map-pin sizing. This keeps search, nearby results, and map presentation consistent.