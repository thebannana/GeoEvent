# Comprehensive Implementation Plan - 16 System Fixes for GeoEvent

This document outlines the detailed step-by-step implementation plan for resolving all 16 problems identified in [Problems.txt](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Problems.txt).

---

## Overview & Executive Summary

The fixes address integrity, security, lifecycle synchronization, performance, and user experience across the GeoEvent ecosystem (Backend Microservices in .NET, Mobile Client in Flutter, Desktop Admin Client in Flutter, and Async Messaging Workers).

---

## Architectural Decisions & Resolved Design Points

1. **Problem 3 (Paid Reservation Refund & Idempotency)**:
   * **Exact Enum Value Alignment**: In `EventService`, event publication transitions an event's status from `EventStatus.Pending` to `EventStatus.Confirmed` (`EventStatus.Confirmed` is the actual enum value representing a published/active event). The implementation plan and code use `EventStatus.Confirmed` (not a non-existent `Published` enum state).
   * **Refund Queue Reuse & Pipeline Protection**: Paid reservations for a cancelled event will reuse the existing `RequestRefund(reason)` domain method, transitioning `RefundRequestStatus` to `RefundRequestStatus.Pending` with a system reason `"Event Cancelled by Organizer"`. This directly satisfies `CanRequestRefund()` preconditions (`Status == ReservationStatus.Confirmed`, `TotalAmount > 0`, `RefundRequestStatus == RefundRequestStatus.None`).
   * **Pre-Existing Refund Request Guard**: To prevent `CanRequestRefund()` from throwing a `BusinessException` and breaking the cancellation loop, `CancelTicketsByEventAsync` will check `if (reservation.RefundRequestStatus == RefundRequestStatus.None)` before calling `RequestRefund()`. If `RefundRequestStatus != RefundRequestStatus.None` (e.g., an attendee already requested a refund before the organizer cancelled), the cancellation loop treats the refund as already in the pipeline and skips re-requesting.
   * **Authoritative Status Check**: Enforce an explicit event `EventStatus.Confirmed` status check both at reservation creation (`CreateReservationAsync`) AND payment confirmation (`ConfirmReservationAsync` / `CaptureReservationPayPalOrderAsync`). If the event status is not `EventStatus.Confirmed`, reservation creation/confirmation is rejected.
   * **Idempotency**: `CancelTicketsByEventAsync` will check if reservations are already cancelled or already in `RefundRequestStatus != RefundRequestStatus.None`. Duplicate `EventCancelledMessage` events will be safely ignored without raising exceptions or duplicating refund queue entries.

2. **Problem 4 (Event Update Lifecycle Boundary)**:
   * **No New `/restore` Endpoint**: A new `/restore` endpoint is **not** required. `EventServiceImpl.UpdateAsync()` will simply preserve the event's existing `Status` without executing implicit status transitions (`Publish()`, `RestoreAsConfirmed()`). Lifecycle transitions remain strictly scoped to explicit endpoints (`/publish`, `/cancel`, `/complete`).

3. **Problem 8 (User vs System Cancellation Reason Separation)**:
   * **Interactive User Cancellation**: In `reservations_screen.dart`, manual user cancellations require a modal prompt where the user enters a cancellation reason string.
   * **Silent Payment Abort Path**: In `payment_controller.dart`, when a user cancels or aborts the PayPal webview checkout, the client executes cleanup using an explicit system reason `"Payment Aborted by User / Payment Flow Cancelled"` without prompting the user or failing.

4. **Problem 9 (Category Deletion Policy)**:
   * **Single Policy — Reject-If-Referenced (HTTP 409 Conflict)**: Category deletion endpoints (`DELETE /api/segments/{id}`, `DELETE /api/genres/{id}`, `DELETE /api/subgenres/{id}`) will check if any existing events reference the category. If referenced, return `409 Conflict` with a clear error message. Physical deletion occurs only when no references exist.

5. **Problem 13 (Dead Code Removal for Individual Ticket Cancellation)**:
   * **Remove Endpoint**: Repository audit confirmed zero UI or controller callers for `CancelTicketAsync` or `PATCH /api/tickets/{id}/cancel` in both Flutter clients (`geo_event` and `geo_event_desktop`). The endpoint and method will be removed completely as dead code, eliminating contradictory state paths between ticket and reservation cancellation.

---

## Detailed Problem Fix Breakdown

### Problem 1: Secure PayPal Reservation Confirmation Flow
* **Issue**: `POST /api/reservations/{reservationId}/confirm` in `ReservationsController.cs` permits confirming PayPal payments purely based on client-provided metadata without server-side verification with PayPal.
* **Solution**: Restrict PayPal reservation confirmation strictly to the verified server-side `CaptureReservationPayPalOrderAsync()` flow. Remove or disable client-driven PayPal payload parsing in generic `ConfirmReservationAsync()`.
* **Relevant Files**:
  * [ReservationsController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.API/Controllers/ReservationsController.cs)
  * [TicketServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Infrastructure/Services/TicketServiceImpl.cs)
  * [ConfirmReservationDto.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Application/DTOs/ConfirmReservationDto.cs)
  * [payment_controller.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/features/payment/application/payment_controller.dart)

### Problem 2: Validate Ticket Belonging to Specified Event
* **Issue**: `CreateReservationDto` accepts `EventId` and `EventTicketId`. `TicketServiceImpl.CreateReservationAsync()` reserves inventory based on `EventTicketId`, but sets `EventId` on the reservation without checking `eventTicket.EventId == dto.EventId`.
* **Solution**: Automatically populate `EventId` directly from `eventTicket.EventId` loaded from the database, or throw a domain validation exception if `dto.EventId` is supplied and does not match `eventTicket.EventId` prior to adjusting ticket inventory.
* **Relevant Files**:
  * [TicketServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Infrastructure/Services/TicketServiceImpl.cs)

### Problem 3: Align Lifecycle & Synchronize EventService and TicketService
* **Issue**: `EventServiceImpl.CreateAsync()` immediately publishes `EventCreatedMessage`, which triggers default ticket creation even while an event is in `Pending` state. `DeleteAsync()` lacks `EventCancelledMessage` publication. `EventUpdatedMessage` fails to convey capacity/price updates, and `Capacity = 0` validation rules conflict between services.
* **Solution**:
  1. Postpone `EventCreatedMessage` until an event is explicitly published via `/publish` (transitioning status from `Pending` to `EventStatus.Confirmed`).
  2. Publish `EventCancelledMessage` upon event deletion/cancellation in `EventServiceImpl.DeleteAsync()` and `AdminDeleteAsync()`.
  3. Update `CancelTicketsByEventAsync` to be idempotent and process reservations: block check-ins, cancel pending unpaid reservations, and for paid reservations check `if (reservation.RefundRequestStatus == RefundRequestStatus.None)` before invoking `RequestRefund("Event Cancelled by Organizer")` (transitioning `RefundRequestStatus` to `Pending`, and skipping reservations already in refund processing).
  4. Include `Capacity` and `Price` in `EventUpdatedMessage` and add consumer logic to synchronize default `General` tickets.
  5. Enforce authoritative `EventStatus.Confirmed` event status check during reservation creation AND payment capture.
  6. Harmonize `Capacity` rules: ensure minimum capacity validation is aligned across both `Event.cs` and `TicketServiceImpl`.
* **Relevant Files**:
  * [EventServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Infrastructure/Services/EventServiceImpl.cs)
  * [EventCreatedMessage.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Events/EventCreatedMessage.cs)
  * [EventCreatedConsumer.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Workers/HelperWorkers/Consumers/EventCreatedConsumer.cs)
  * [TicketServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Infrastructure/Services/TicketServiceImpl.cs)
  * [EventUpdatedMessage.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Events/EventUpdatedMessage.cs)

### Problem 4: Preserve Lifecycle Status During General Event Updates
* **Issue**: `EventServiceImpl.UpdateAsync()` implicitly alters event status (e.g., executing `RestoreAsConfirmed()` or `Publish()`) when basic event details (title, description, date) are updated.
* **Solution**: Remove status mutation logic from `UpdateAsync()`. Preserve existing event status without introducing new endpoints. Require all status transitions to occur exclusively through dedicated endpoints (`/publish`, `/cancel`, `/complete`).
* **Relevant Files**:
  * [EventServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Infrastructure/Services/EventServiceImpl.cs)
  * [UpdateEventDto.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Application/DTOs/UpdateEventDto.cs)

### Problem 5: Restrict Organizer Ability to Set IsFeatured
* **Issue**: Organizers can pass `IsFeatured` in `UpdateEventDto`, allowing self-promotion without administrator authorization.
* **Solution**: Remove `IsFeatured` handling from standard organizer update paths in `EventServiceImpl.UpdateAsync()`. Separate organizer and admin DTOs or restrict `IsFeatured` modifications strictly to `AdminEventsController`.
* **Relevant Files**:
  * [EventServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Infrastructure/Services/EventServiceImpl.cs)
  * [AdminEventsController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.API/Controllers/AdminEventsController.cs)
  * [UpdateEventDto.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Application/DTOs/UpdateEventDto.cs)

### Problem 6: Persist Refresh Token Revocation on Logout
* **Issue**: `AuthService.LogoutAsync()` calls `UserRepository.RevokeRefreshTokenAsync()`, but the token entity revocation is never saved to the database because `SaveChangesAsync()` is omitted.
* **Solution**: Add `await _context.SaveChangesAsync()` inside `UserRepository.RevokeRefreshTokenAsync()` or immediately after invocation in `AuthService.LogoutAsync()`. Verify that revoked tokens cannot be exchanged for new access tokens.
* **Relevant Files**:
  * [AuthService.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Infrastructure/Services/AuthService.cs)
  * [UserRepository.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Infrastructure/Repositories/UserRepository.cs)

### Problem 7: Transmit Valid EventId in Reservation Cancellation Integration Messages
* **Issue**: `TicketServiceImpl.CancelReservationAsync()` publishes `ReservationCancelledIntegrationMessage` with a hardcoded or zero `EventId` (0), preventing `ReservationCancelledIntegrationConsumer` from removing the user from the correct chat group.
* **Solution**: Capture `reservation.EventId` prior to state mutations and pass the actual `EventId` into `ReservationCancelledIntegrationMessage`.
* **Relevant Files**:
  * [TicketServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Infrastructure/Services/TicketServiceImpl.cs)
  * [ReservationCancelledIntegrationMessage.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Reservations/ReservationCancelledIntegrationMessage.cs)
  * [ReservationCancelledIntegrationConsumer.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Workers/HelperWorkers/Consumers/ReservationCancelledIntegrationConsumer.cs)

### Problem 8: Reservation Cancellation Audit & Notification Flow
* **Issue**: `Reservation` domain entity lacks audit metadata (`CancelledByUserId`, `CancellationReason`), and user cancellation fails to issue in-app notifications to the counterparty.
* **Solution**:
  1. Add audit properties (`CancelledByUserId`, `CancellationReason`) to `Reservation.cs` and migration/entities.
  2. Update API cancellation endpoints to accept a cancellation reason DTO.
  3. In `payment_controller.dart` silent abort path, supply system reason `"Payment Aborted by User / Payment Flow Cancelled"`. In mobile `reservations_screen.dart`, prompt user for typed reason.
  4. Publish `ReservationCancelledMessage` upon cancellation to trigger in-app notifications for the counterparty.
* **Relevant Files**:
  * [Reservation.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Domain/Entities/Reservation.cs)
  * [ReservationCancelledMessage.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Tickets/ReservationCancelledMessage.cs)
  * [NotificationType.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/Shared.Contracts/Shared.Contracts/Enums/NotificationType.cs)
  * [tickets_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/shared/tickets/data/tickets_api.dart)
  * [reservations_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/shared/reservations/data/reservations_api.dart)
  * [reservations_controller.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/features/reservations/application/reservations_controller.dart)
  * [reservations_screen.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/features/reservations/presentation/screens/reservations_screen.dart)
  * [payment_controller.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/features/payment/application/payment_controller.dart)

### Problem 9: Implement Full CRUD Deletion for Category Taxonomy (Reject-If-Referenced)
* **Issue**: `SegmentsController`, `GenresController`, and `SubGenresController` lack `DELETE` actions. Desktop admin panels lack category deletion.
* **Solution**:
  1. Implement `DELETE` actions in backend controllers returning `409 Conflict` if active events reference the category entity. Allow deletion only if zero references exist.
  2. Update desktop `admin_categories_api.dart` and `admin_categories_panel.dart` to support category deletion with error handling for 409 Conflict responses.
* **Relevant Files**:
  * [SegmentsController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.API/Controllers/SegmentsController.cs)
  * [GenresController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.API/Controllers/GenresController.cs)
  * [SubGenresController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.API/Controllers/SubGenresController.cs)
  * [admin_categories_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/shared/admin_profile/data/admin_categories_api.dart)
  * [admin_categories_panel.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/features/shell/presentation/widgets/admin_categories_panel.dart)

### Problem 10: Explainable Recommender Engine Signals
* **Issue**: The recommender engine returns a numeric score (`RecommendationScore`) without human-understandable context or explanation.
* **Solution**:
  1. Add `RecommendationReason` (or `WhyRecommended`) string property to `EventResponseDTO`.
  2. Update `EventRepository` recommender queries to generate natural text explanations (e.g., "Recommended because you frequently attend Tech events in your city").
  3. Display recommendation reasons in the mobile app event card/detail view.
* **Relevant Files**:
  * [EventRepository.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Infrastructure/Repositories/EventRepository.cs)
  * [EventResponseDTO.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Application/DTOs/EventResponseDTO.cs)
  * [create_event_models.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/shared/events/models/create_event_models.dart)

### Problem 11: Desktop Desktop Registration Screen & Auth Flow
* **Issue**: Desktop client has registration endpoints configured in constants/APIs but lacks a registration screen and UI navigation route.
* **Solution**:
  1. Add `register_screen.dart` to `frontend/geo_event_desktop/lib/features/auth/presentation/screens/`.
  2. Connect form submission to `auth_api.dart` registration call without exposing privilege/role self-assignment fields.
  3. Provide navigation toggle between Login and Registration screens in desktop auth UI.
* **Relevant Files**:
  * [api_endpoints.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/core/network/api_endpoints.dart)
  * [auth_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/shared/auth/data/auth_api.dart)
  * `frontend/geo_event_desktop/lib/features/auth/presentation/screens/register_screen.dart` (New File)
  * [RegisterRequestDto.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Application/DTOs/RegisterRequestDto.cs)
  * [AuthService.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Infrastructure/Services/AuthService.cs)
  * [register_screen.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/features/auth/presentation/screens/register_screen.dart)

### Problem 12: Backend Validation of Category Hierarchy (Segment -> Genre -> SubGenre)
* **Issue**: Event creation and updates permit mismatched category selection (e.g., SubGenre not belonging to selected Genre, or Genre not belonging to Segment).
* **Solution**: Add backend validator method `ValidateCategoryHierarchyAsync()` in `EventServiceImpl` executed on `CreateAsync` and `UpdateAsync` to ensure FK parent-child relationships are strictly consistent.
* **Relevant Files**:
  * [EventServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Infrastructure/Services/EventServiceImpl.cs)
  * [UpdateEventDto.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.Application/DTOs/UpdateEventDto.cs)

### Problem 13: Remove Dead Ticket Cancellation Endpoint
* **Issue**: `TicketsController` exposes `[HttpPatch("{ticketId:int}/cancel")]` and `CancelTicketAsync` which lacks reservation/payment integration. Zero UI or controller callers exist in the codebase.
* **Solution**: Delete the dead `[HttpPatch("{ticketId:int}/cancel")]` endpoint from `TicketsController.cs`, remove `CancelTicketAsync` from `TicketServiceImpl.cs`, and clean up `cancelTicket` in Flutter `api_endpoints.dart`.
* **Relevant Files**:
  * [TicketsController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.API/Controllers/TicketsController.cs)
  * [TicketServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Infrastructure/Services/TicketServiceImpl.cs)
  * [ITicketService.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/TicketService/TicketService.Application/Interfaces/Services/ITicketService.cs)
  * [api_endpoints.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/core/network/api_endpoints.dart)
  * [api_endpoints.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/core/network/api_endpoints.dart)

### Problem 14: Eliminate N+1 Database and HTTP Fan-Out in Admin Reports View
* **Issue**: `UserServiceImpl.GetAllReportsAsync()` sequentially resolves targets (`MapAdminReportAsync` -> `ResolveReportTargetAsync`), incurring N+1 database/HTTP calls for N reports.
* **Solution**: Refactor to batch-resolve targets by entity type prior to mapping, reducing N+1 queries to a fixed 2-3 batch lookups regardless of page size.
* **Relevant Files**:
  * [UserServiceImpl.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Infrastructure/Services/UserServiceImpl.cs)

### Problem 15: Enforce Default Pagination on Segments Controller
* **Issue**: `SegmentsController.GetAll()` defaults to `paged = false`, exposing an unpaginated query path that fetches all segments.
* **Solution**:
  1. Enforce default pagination (`paged = true`) with a strict maximum `pageSize` limit (e.g., max 100).
  2. Update desktop and mobile API clients to handle paginated taxonomy responses properly.
* **Relevant Files**:
  * [SegmentsController.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/EventService/EventService.API/Controllers/SegmentsController.cs)
  * [events_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/shared/events/data/events_api.dart)
  * [event_taxonomy_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event/lib/shared/profile/data/event_taxonomy_api.dart)
  * [admin_categories_api.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/shared/admin_profile/data/admin_categories_api.dart)
  * [edit_event_screen.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/features/shell/presentation/screens/edit_event_screen.dart)
  * [EventInternalClient.cs](file:///d:/GeoEvent_Repo/GeoEvent/backend/geoEvent/src/UserService/UserService.Infrastructure/Services/EventInternalClient.cs)

### Problem 16: Desktop Confirmation Dialog for Event Image Deletion
* **Issue**: Deleting event images in desktop `edit_event_screen.dart` (`_removeExistingImage()`) invokes direct API deletion without user confirmation.
* **Solution**: Introduce a modal confirmation dialog (`showDialog`) asking the admin to confirm image deletion before triggering `adminDeleteEventImage()`.
* **Relevant Files**:
  * [edit_event_screen.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/features/shell/presentation/screens/edit_event_screen.dart)
  * [admin_events_panel.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/features/shell/presentation/widgets/admin_events_panel.dart)
  * [admin_users_panel.dart](file:///d:/GeoEvent_Repo/GeoEvent/frontend/geo_event_desktop/lib/features/shell/presentation/widgets/admin_users_panel.dart)

---

## Phase Execution Breakdown

### Phase 1: Core Backend & Security Fixes
* **Target Problems**: 1, 2, 6, 7, 8, 13
* **Tasks**:
  1. Revamp `ReservationsController` & `TicketServiceImpl` PayPal confirmation checks.
  2. Enforce `EventId` consistency in `CreateReservationAsync`.
  3. Ensure `AuthService` and `UserRepository` save refresh token revocation on logout.
  4. Fix `EventId` transmission in `ReservationCancelledIntegrationMessage`.
  5. Add reservation cancellation audit fields, separate user prompt from silent PayPal abort reason, and publish notification events.
  6. Remove dead `CancelTicketAsync` endpoint and interface method.

### Phase 2: Domain Lifecycle, Event Management & Taxonomy Hierarchy
* **Target Problems**: 3, 4, 5, 12, 15
* **Tasks**:
  1. Decouple initial ticket creation from `Pending` event status; synchronize status changes across `EventService` and `TicketService`.
  2. Preserve event status during general updates in `UpdateAsync()` without introducing new endpoints.
  3. Enforce authoritative `EventStatus.Confirmed` event status check during reservation creation and payment capture.
  4. Implement idempotent handling for duplicate `EventCancelledMessage` handling.
  5. Block non-admin `IsFeatured` updates.
  6. Enforce `Segment -> Genre -> SubGenre` hierarchy validation in `EventServiceImpl`.
  7. Apply standard pagination and limits to `SegmentsController.GetAll()`.

### Phase 3: Performance, Recommender & Taxonomy Deletion
* **Target Problems**: 9, 10, 14
* **Tasks**:
  1. Batch resolution of report targets in `UserServiceImpl.GetAllReportsAsync()`.
  2. Implement backend `DELETE` endpoints for taxonomy entities with `409 Conflict` reference checks.
  3. Enrich recommendation response DTOs with human-readable textual reasons.

### Phase 4: Frontend Applications (Mobile & Desktop)
* **Target Problems**: 8 (UI), 9 (UI), 10 (UI), 11, 15 (UI), 16
* **Tasks**:
  1. Build `register_screen.dart` in the desktop application and link navigation.
  2. Implement confirmation modal for image deletion in desktop `edit_event_screen.dart`.
  3. Add UI support for category deletion in desktop `admin_categories_panel.dart`.
  4. Render recommendation reasons on mobile event cards/details.
  5. Update Flutter API calls to supply reasons for reservation cancellations and handle paginated segment lists.

---

## Comprehensive Verification Plan

### Automated Verification
* Run unit tests for `TicketService`, `EventService`, and `UserService` using `.NET CLI`:
  `dotnet test backend/geoEvent/src/`
* Verify Flutter web/desktop compilation:
  `flutter analyze` inside `frontend/geo_event` and `frontend/geo_event_desktop`.

### Specific Verification Scenarios

1. **Problem 1 (PayPal Verification Security)**:
   * **Test**: Send `POST /api/reservations/{id}/confirm` with mock PayPal metadata.
   * **Result**: Request is rejected; server requires `CaptureReservationPayPalOrderAsync()`.

2. **Problem 2 (EventId Mismatch Prevention)**:
   * **Test**: Attempt creating a reservation with mismatched `EventId` and `EventTicketId`.
   * **Result**: Server rejects creation with validation error prior to adjusting ticket inventory.

3. **Problem 3 (Lifecycle Alignment & Idempotency)**:
   * **Test A**: Attempt creating a reservation for an event in `Pending` state.
   * **Result A**: Reservation rejected with error `"Event is not published"`.
   * **Test B**: Publish event, reserve tickets, then cancel event. Send `EventCancelledMessage` twice.
   * **Result B**: First invocation cancels unpaid reservations, moves paid reservations to `RefundRequestStatus.Pending` with reason `"Event Cancelled by Organizer"`. Second invocation completes idempotently without error or duplicate refund entries.

4. **Problem 4 (Status Preservation on Update)**:
   * **Test**: Update event title/description for a `Pending` or `Cancelled` event via `PUT /api/events/{id}`.
   * **Result**: Event data is updated, but status remains unchanged (`Pending` or `Cancelled`).

5. **Problem 5 (IsFeatured Authorization)**:
   * **Test**: Submit organizer `PUT /api/events/{id}` with `isFeatured: true`.
   * **Result**: `isFeatured` remains unchanged (`false`). Only admin endpoint can toggle `isFeatured`.

6. **Problem 6 (Logout Refresh Token Persistence)**:
   * **Test**: Execute login -> logout -> attempt token refresh with original refresh token.
   * **Result**: Refresh endpoint returns HTTP 401 Unauthorized because revocation was saved to DB.

7. **Problem 7 (EventId in Cancellation Integration Message)**:
   * **Test**: User cancels a reservation. Inspect message bus event `ReservationCancelledIntegrationMessage`.
   * **Result**: Message contains the actual `EventId` (not `0`), and user is removed from the correct event chat thread.

8. **Problem 8 (Reservation Cancellation Audit & Reason Paths)**:
   * **Test A (User UI)**: Cancel reservation in mobile UI; verify prompt requires entering a reason, which is saved in `CancellationReason`.
   * **Test B (PayPal Abort)**: Abort PayPal checkout; verify `cancelReservation` is invoked silently with system reason `"Payment Aborted by User / Payment Flow Cancelled"`.

9. **Problem 9 (Category Deletion Deletion Policy - 409 Conflict)**:
   * **Test A**: Issue `DELETE /api/segments/{id}` for a segment referenced by an active event.
   * **Result A**: Returns `409 Conflict` with error message `"Cannot delete segment because it is referenced by existing events."`
   * **Test B**: Issue `DELETE /api/segments/{id}` for an unreferenced segment.
   * **Result B**: Returns `204 No Content` / `200 OK` and removes segment from database.

10. **Problem 10 (Recommender Explainability)**:
    * **Test**: Query `/api/events/recommended`.
    * **Result**: Response items include non-null `recommendationReason` string (e.g., `"Recommended based on your interest in Technology"`), displayed in mobile UI.

11. **Problem 11 (Desktop Registration Flow)**:
    * **Test**: Navigate to Desktop auth screen -> Click Register -> Complete form and submit.
    * **Result**: Account is created as standard user without admin privilege self-assignment.

12. **Problem 12 (Category Hierarchy Validation)**:
    * **Test**: Submit `CreateEventDto` or `UpdateEventDto` with Genre ID 5 and SubGenre ID 12 (where SubGenre 12 does not belong to Genre 5).
    * **Result**: Backend validation throws `400 Bad Request` with error `"Selected SubGenre does not belong to the selected Genre."`

13. **Problem 13 (Dead Ticket Cancellation Endpoint Removal)**:
    * **Test**: Issue `PATCH /api/tickets/123/cancel`.
    * **Result**: Server returns `404 Not Found` because dead endpoint was removed.

14. **Problem 14 (Admin Reports N+1 Query Call Count Reduction)**:
    * **Before**: Requesting 20 admin reports executed 1 initial report query + 20 sequential target lookup queries (Total: 21 queries).
    * **After**: Requesting 20 admin reports executes 1 initial report query + 2 batched target queries grouped by type (Total: 3 queries).
    * **Test**: Request `/api/admin/reports` with 20 items and inspect SQL log query count.
    * **Result**: Query count is fixed (3 queries) regardless of report page size.

15. **Problem 15 (Segments Default Pagination)**:
    * **Test**: Query `GET /api/segments` without query parameters.
    * **Result**: Returns paginated structure with default page size and total count headers/metadata.

16. **Problem 16 (Desktop Image Deletion Confirmation Modal)**:
    * **Test**: Click delete icon on an event image in desktop `edit_event_screen.dart`.
    * **Result**: Modal confirmation dialog appears. Clicking Cancel leaves image intact; clicking Confirm invokes DELETE API.

