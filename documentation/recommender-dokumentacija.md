# GeoEvent Recommendation System

## Overview

GeoEvent uses a backend-controlled hybrid recommendation system. It combines content-based preference matching with context-aware signals such as the user's location, event popularity, featured status, and search text.

The backend is the single source of truth for recommendation ranking. Flutter does not calculate a second recommendation score. It displays events in the order returned by the backend and uses the returned `recommendationScore` for map-pin sizing.

Every recommendation can be explained through the factors that contributed to its score.

## User preferences

User preferences are stored in the database and updated from user interactions with events.

The supported interactions and their preference increments are:

- Like
- Bookmark
- Comment
- Confirmed reservation

These interactions represent accumulated interest in event segments, genres, and subgenres. A confirmed reservation carries the strongest weight because it represents a stronger intent than a like, bookmark, or comment.

Preference records preserve their hierarchy. A specific genre or subgenre preference includes its parent segment and genre IDs, allowing the backend to match the complete event taxonomy correctly.

## Backend scoring

When a logged-in user enables preference-based results, the backend loads that user's preferences and calculates an overall recommendation score for every filtered candidate before sorting and pagination.

The recommendation score evaluates several factors:
- **Preference Match:** How closely the event's category aligns with the user's historical interactions. More specific matches (e.g., matching the exact subgenre instead of just the segment) yield a much higher score.
- **Distance:** How close the event is to the user's current GPS location. Closer events receive a higher score bonus.
- **Popularity:** A calculation of likes and views to ensure popular events get a boost without completely dominating personal relevance.
- **Featured Status:** Administratively featured events receive a fixed bonus to increase their visibility.
- **Search Relevance:** When a user searches for text, events with matching titles, descriptions, and tags receive extra points.

The backend sorts candidates primarily by their total recommendation score in descending order, falling back to start date and likes for tie-breaking.

## Nearby and global results

For nearby results, the backend filters candidates using a geographic bounding box, calculates exact distances and recommendation scores, and then returns the requested limit.

For global search, the backend applies standard filters, scores all matching candidates, sorts them, and then applies pagination. This ensures the first page always contains the absolute best matches from the entire dataset.

## Flutter responsibilities

Flutter does not calculate recommendation scores. Its responsibilities are limited to:

- Sending filter values and preferences flags to the backend.
- Sending device coordinates for location-aware requests.
- Parsing the `recommendationScore` and displaying results in the provided order.
- Using the backend score to size map pins (e.g., higher scores result in larger map pins).

## "Recommended for you" Feature

To improve explainability and user experience, the system includes a **"Recommended for you"** feature. 

When the backend identifies that an event is highly recommended based on a user's specific interactions (such as past preferences), it computes a textual `RecommendationReason` (e.g., "Recommended based on your preferences").

The mobile UI parses this reason and prominently displays it on the event cards (such as in search) alongside an icon. This directly informs the user *why* an event was surfaced to them, significantly enhancing transparency and trust in the recommendation engine.