# GeoEvent Recommendation System

## Overview

GeoEvent uses a backend-controlled hybrid recommendation system. It combines content-based preference matching with context-aware signals such as the user's location, event popularity, featured status, and search text.

The backend is the single source of truth for recommendation ranking. Flutter does not calculate a second recommendation score. It displays events in the order returned by the backend, uses the returned `recommendationScore` for map-pin sizing, and shows the returned `recommendationReason` as a short explanation on each result.

Every recommended event can be explained through the signals that contributed most to its ranking.

## User preferences

User preferences are stored in the database and updated automatically from user interactions with events.

The supported interactions are:

- Like
- Bookmark
- Comment
- Confirmed reservation

These interactions represent accumulated interest in event segments, genres, and subgenres. The stronger the interaction, the more interest it adds: a confirmed reservation carries the strongest weight because it shows clearer intent than a like, a bookmark, or a comment. An interaction also adds more interest to the more specific category levels, so repeatedly engaging with a particular subgenre builds a more precise profile than engaging with a whole segment.

Preference records preserve their hierarchy. A specific genre or subgenre preference includes its parent segment and genre, allowing the backend to match the complete event taxonomy correctly. Interactions are processed asynchronously through the message queue, so a new interaction is reflected in recommendations shortly after it happens rather than instantly.

## Which events are considered

Only events that are confirmed (published) and have not yet ended are ever recommended. Pending, rejected, cancelled, and past events are never candidates. Any filters chosen by the user (category, price range, date range, featured only, and so on) are applied first, and only the events that pass them are ranked.

## Backend scoring

When a logged-in user enables preference-based results, or when nearby results are requested, the backend loads the user's preferences and calculates an overall recommendation score for every candidate before sorting and pagination.

The recommendation score is built from several signals:

- **Preference match:** How closely the event's category fits the user's accumulated interests. A more specific match (for example the exact subgenre rather than just the segment) counts for much more, and a stronger interest in that category counts for more as well.
- **Distance:** How close the event is to the user's current location. Events very close to the user receive the full bonus, and the bonus gradually shrinks to nothing as the event approaches the edge of the search radius.
- **Popularity:** Likes and views raise the score so that well-liked events get a boost. The effect is softened and capped so popularity helps but never completely overrides personal relevance.
- **Featured status:** Events marked as featured receive a fixed bonus to increase their visibility. Only administrators can mark an event as featured; organizers cannot set this flag on their own events.
- **Search relevance:** When the user searches for text, events that contain the search term receive a large bonus. A match in the title matters most, then the description, then the tags. This signal is intentionally dominant, so events that actually match the search normally appear first.

Events are sorted primarily by their total score from highest to lowest. When scores are equal, events that start sooner come first, and then events with more likes.

If the user is not logged in, or has not enabled preference-based results, global browsing does not use recommendation ranking. Events are then returned using the normal sort order chosen by the user (by default, soonest first), and no recommendation reason is shown.

## Nearby and global results

For nearby results, the backend first selects candidates inside a rectangular area around the user that is sized from the search radius, then calculates exact distances and scores, and finally returns the requested number of best-ranked events. Nearby results are always scored using distance, popularity, and featured status, even for anonymous users. Preferences are added on top of that for logged-in users who enable them. Events in the corners of the rectangular area that lie beyond the radius receive no distance bonus.

For global search, the backend applies the standard filters, scores all matching candidates, sorts them, and only then applies pagination. This ensures the first page contains the best matches from the entire result set rather than only from the first page of data.

## Flutter responsibilities

Flutter does not calculate recommendation scores. Its responsibilities are limited to:

- Sending filter values and the personalization flag to the backend.
- Sending device coordinates for location-aware requests.
- Displaying results in the order the backend returns them.
- Using the backend score to size map pins, so that higher-ranked events appear as larger pins.
- Displaying the backend's recommendation reason on result cards.

## "Recommended for you" feature

To make recommendations transparent, each ranked event can carry a short, human-readable reason explaining why it was surfaced.

The reason is not a fixed label. The backend looks at the signals that actually applied to that specific event for that specific user, picks the strongest one, and phrases it using real data. Depending on which signal was strongest, the reason can mention:

- **The user's interests,** naming the category behind the strongest matching interest, for example "Because you showed interest in Rock".
- **The search text,** for example a message stating the event matches the user's search for a specific word.
- **The distance,** for example how many kilometres away the event is, or that it is less than a kilometre away.
- **Popularity,** for example how many people liked the event, or that it is frequently viewed by other users. This is only used when the event is clearly more popular than average.
- **Featured status,** stating that the event is featured by GeoEvent.

A search match wins over everything else because it is the most direct signal. Beyond that, the signal that contributed the most to the event's score is the one that is explained. A preference is only named when the user's interest points to a real category; very general preferences that do not name any category are not used as an explanation. If no signal is meaningful enough to explain an event, no reason is returned and nothing is shown.

The mobile app displays the reason, together with a small sparkle icon, on the search result cards and on the result cards of the map search. This tells users why an event was surfaced for them and makes the recommendation engine easier to trust.