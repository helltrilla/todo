# Architecture

## 1. Overview

The project follows a pragmatic Clean Architecture approach.

The main goal is to keep:

- UI;
- application coordination;
- business logic;
- data access;
- external APIs;
- persistent storage

separated from each other.

The architecture should remain simple.

Do not introduce additional abstraction layers unless they solve a real problem.

---

# 2. High-Level Architecture

The general dependency flow is:

```text
┌─────────────────────────────┐
│            UI               │
│   Screens / Widgets / UX    │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│      Application Layer      │
│ Coordination / State / Flow │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│       Service Layer         │
│ Business operations / APIs  │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│      Data / External        │
│ APIs / Storage / Platform   │
└─────────────────────────────┘
```

Models are shared between the relevant layers and represent structured application data.

The exact implementation may vary by feature, but the direction of dependencies should remain predictable.

---

# 3. Project Structure

The project follows a **Feature-First Clean Architecture**:

```text
lib/
├── core/                              # Global foundation and cross-cutting concerns
│   ├── config/                        # AppConfig (--dart-define overrides)
│   ├── constants/                     # AppConstants, AppStrings, MapLayerConstants
│   ├── errors/                        # Failures, Exceptions, and Result monad
│   ├── network/                       # Network client utilities
│   └── theme/                         # AppTheme and design tokens
│
├── features/                          # Domain-driven feature packages
│   ├── map/                           # Base map canvas, tile layers, attribution
│   │   ├── domain/                    # Tile styles and configuration models
│   │   └── presentation/              # MapScreen composition, attribution, markers
│   ├── markers/                       # Saved pins & bookmark storage
│   │   ├── data/                      # SharedPreferences repository & migration
│   │   ├── domain/                    # SavedMarker models and repository interface
│   │   └── presentation/              # MarkersController (StateNotifier)
│   ├── places/                        # Overpass POI discovery & details
│   │   ├── data/                      # OverpassDataSource with mirror failover
│   │   ├── domain/                    # Place and PlaceReview models
│   │   └── presentation/              # PlacesController, PlaceDetailsSheet
│   ├── routing/                       # OSRM turn-by-turn routing
│   │   ├── data/                      # OsrmDataSource
│   │   ├── domain/                    # RouteInfo model and router interface
│   │   └── presentation/              # RoutingController, RoutePlannerSheet
│   └── search/                        # Photon & Nominatim geocoding
│       ├── data/                      # PhotonDataSource with Nominatim fallback
│       ├── domain/                    # SearchResult model and search interface
│       └── presentation/              # SearchController, FloatingSearchBar
│
├── main.dart                          # Application entry point with ProviderScope
├── main_screen.dart                   # Composed screen coordinator (~420 lines)
│
└── (compatibility facades)            # Re-exports maintained for seamless backward compatibility
    ├── models/                        # Re-exports feature domain models
    ├── services/                      # Service facades delegating to data sources
    └── widgets/                       # Re-exports feature presentation widgets
```

## `main.dart`

Application entry point.

Responsibilities:

- initialize Flutter bindings;
- wrap the root widget tree in `ProviderScope` for Riverpod dependency injection;
- configure global application theme (`AppTheme.darkTheme`);
- perform only necessary startup configuration.

Do not place feature-specific business logic here.

---

## `main_screen.dart`

Modular composition coordinator.

It is responsible for assembling feature components into a cohesive single-screen experience:

- watches Riverpod state providers (`ref.watch`);
- hosts the `FlutterMap` widget and active tile layer;
- renders overlay widgets (`FloatingSearchBar`, `MapAttributionWidget`, GPS control buttons);
- opens modular modal sheets (`PlaceDetailsSheet`, `RoutePlannerSheet`);
- delegates actions directly to feature controllers (`ref.read(...notifier)`).

Business logic, HTTP calls, and JSON parsing must never reside in `main_screen.dart`.

---

# 4. Domain Layer & Models

Models represent structured application data and reside within their corresponding feature domain:

```text
features/
├── map/domain/models/map_tile_style.dart
├── markers/domain/models/saved_marker.dart
├── places/domain/models/place.dart
├── places/domain/models/place_review.dart
├── routing/domain/models/route_info.dart
└── search/domain/models/search_result.dart
```

Backward-compatible re-exports are provided under `lib/models/`.

Rules for models:

- Models are immutable data holders.
- Models should not perform HTTP calls or touch persistent storage.
- Models contain serialization (`fromJson`, `toJson`) and purely local helpers (formatting, distance calculations).
- A model should not depend on UI widgets or platform-specific APIs.

---

# 5. Data Sources & Repositories

External communication and persistence are isolated in the `data` layer behind domain interfaces:

```text
features/
├── markers/
│   ├── domain/repositories/marker_repository.dart      # Interface
│   └── data/repositories/marker_repository_impl.dart   # Implementation (SharedPreferences)
├── places/
│   └── data/datasources/overpass_datasource.dart       # Overpass API with mirror failover
├── routing/
│   └── data/datasources/osrm_datasource.dart           # OSRM HTTP client
└── search/
    └── data/datasources/photon_datasource.dart         # Photon API with Nominatim fallback
```

## Data layer responsibilities:

- **DataSources**: Execute raw HTTP requests or platform calls, validate status codes, handle timeouts, and parse JSON into domain models.
- **Failover & Resilience**: When a remote mirror fails (e.g., HTTP 504), datasources automatically rotate mirrors or fall back to secondary providers.
- **Result Monad**: Operations return `Result<T>` (`Success<T>` or `Error<T>`) wrapping strongly typed `Failure` objects (`ServerFailure`, `NetworkFailure`, `CacheFailure`) instead of throwing uncaught exceptions.
- **Injectable Clients**: All data sources accept an `http.Client` parameter for deterministic testing with `MockClient`.

---

# 6. Presentation Layer & State Management

UI components and screen controllers reside in `presentation/`:

```text
features/
├── map/presentation/
│   ├── widgets/map_attribution_widget.dart
│   ├── widgets/map_marker_widgets.dart
│   └── widgets/layer_switcher_dialog.dart
├── places/presentation/
│   ├── controllers/places_controller.dart
│   └── widgets/place_details_sheet.dart
├── routing/presentation/
│   ├── controllers/routing_controller.dart
│   ├── widgets/route_planner_sheet.dart
│   └── widgets/route_header_card.dart
└── search/presentation/
    ├── controllers/search_controller.dart
    └── widgets/search_bar_widget.dart
```

## Riverpod Controllers:

- Controllers extend `StateNotifier<T>` to manage reactive state.
- Widgets consume state via `ref.watch(controllerProvider)` and dispatch events via `ref.read(controllerProvider.notifier).method()`.
- Controllers do not hold BuildContext references.

## Widgets:

- Pure UI rendering and gesture handling.
- Local animations and transient UI states (e.g. text field controllers, sheet expansion).
- Surface user intent to controllers or parent callbacks.

Prefer:

```text
Widget
   ↓ (user action)
Controller (StateNotifier)
   ↓
Repository / DataSource
   ↓
Result<T>
   ↓
Controller updates state
   ↓
Widget re-renders
```

over:

```text
Widget
   ↓
HTTP request
   ↓
setState()
```

---

# 7. Dependency Direction

Dependencies should generally flow toward lower-level functionality.

Preferred:

```text
Widget
  ↓
Application coordination
  ↓
Service
  ↓
External system
```

Avoid circular dependencies.

For example:

```text
Service → Widget
```

should generally not exist.

A service should not depend on a specific UI component.

Similarly, models should remain independent of UI implementation.

---

# 8. UI vs Business Logic

A useful rule:

> If the logic can be described without mentioning a widget, it probably does not belong inside the widget.

For example, this belongs outside UI:

```text
Find nearby places
Sort results by distance
Calculate route
Save marker
Load cached data
Handle API fallback
```

While this belongs to UI:

```text
Show loading indicator
Display search results
Animate a panel
Respond to a tap
Display an error message
```

---

# 9. External APIs

External services should be accessed through dedicated services.

The project currently integrates with:

```text
OpenStreetMap
OSRM
Overpass API
Photon API
```

The README defines these as the map, routing, POI, and geocoding infrastructure.

UI code should not contain raw API implementation unless there is a strong reason.

Instead:

```text
UI
 ↓
Service
 ↓
API
```

This makes external integrations easier to:

- replace;
- test;
- cache;
- retry;
- mock;
- debug.

---

# 10. API Failure Handling

External APIs are unreliable by nature.

Services should account for:

- connection failures;
- timeouts;
- HTTP errors;
- malformed responses;
- empty responses;
- rate limits;
- temporary service unavailability.

Failure handling should happen as close as possible to the integration layer.

The UI should receive a meaningful result or error state rather than needing to understand HTTP implementation details.

---

# 11. Caching

Caching belongs close to the data/integration layer.

The project uses local tile and HTTP caching through:

```text
flutter_map_cache
dio_cache_interceptor
```

according to the project documentation.

Caching should not leak implementation details into unrelated UI components.

A widget should request data.

It should not need to know whether that data came from:

```text
network
cache
fallback
local storage
```

unless that information is specifically relevant to the UI.

---

# 12. Location

Location access belongs to the location service.

The current project uses a dedicated:

```text
LocationService
```

for GPS and permissions.

UI components should consume location state rather than directly duplicating permission and GPS logic.

If another feature requires location:

```text
Feature
   ↓
LocationService
```

Do not create a second independent location implementation.

---

# 13. Persistent Storage

Persistent data should be isolated from UI.

The project currently uses:

```text
MarkerStorage
```

for saved markers and `shared_preferences` as the underlying storage mechanism.

Preferred flow:

```text
Widget
   ↓
Application logic
   ↓
Storage service
   ↓
Persistent storage
```

The UI should not directly manage serialization formats or storage keys unless the existing architecture explicitly requires it.

---

# 14. Map Responsibilities

Map-related functionality should remain separated by responsibility.

Conceptually:

```text
Map UI
   │
   ├── Tile configuration
   ├── Markers
   ├── Location
   ├── Search
   ├── Routes
   └── User interactions
```

Do not put all map functionality into one class.

For example:

```text
Tile configuration
→ map tile model/configuration

Location
→ LocationService

Places
→ PlacesService

Routing
→ RoutingService

Search
→ SearchService

Saved markers
→ MarkerStorage

UI representation
→ widgets
```

---

# 15. Search Flow

Search should follow a layered flow.

Conceptually:

```text
User input
    ↓
Search UI
    ↓
Search coordination
    ↓
SearchService
    ↓
Photon / external provider
    ↓
SearchResult
    ↓
UI
```

Search-specific presentation logic belongs in the UI.

Search/network logic belongs in the service.

Search result structure belongs in the model.

---

# 16. Place Details Flow

Place details may require multiple data sources.

The conceptual flow is:

```text
Selected place
      ↓
Place details coordination
      ↓
PlaceDetailsService
      ↓
External data sources
      ↓
Place / Review / Media data
      ↓
PlaceDetailsSheet
```

The details UI should not need to understand how additional information was retrieved.

---

# 17. Routing Flow

Routing follows:

```text
Start point
      +
Destination
      ↓
RoutingService
      ↓
OSRM
      ↓
RouteInfo
      ↓
Map / Route UI
```

The routing service is responsible for communication with the routing provider and converting the response into application data.

The UI is responsible for presenting the route.

---

# 18. State Management

State should have a clear owner.

Before adding new state, determine:

```text
Who owns this state?
Who modifies it?
Who reads it?
How long should it live?
```

Do not duplicate the same state across multiple widgets without a reason.

Avoid global mutable state unless the application architecture explicitly requires it.

Prefer keeping state as close as possible to the component that owns the behavior.

If state is shared by multiple independent components, move it to an appropriate coordination layer.

---

# 19. Adding a New Feature

When implementing a new feature, follow:

```text
1. Understand the feature
        ↓
2. Identify existing models
        ↓
3. Identify existing services
        ↓
4. Reuse existing functionality
        ↓
5. Add or modify model if required
        ↓
6. Add service logic if required
        ↓
7. Add UI components
        ↓
8. Connect everything through the appropriate coordinator
        ↓
9. Add tests
        ↓
10. Verify
```

Do not start by modifying the largest screen.

Start by identifying where the new responsibility belongs.

---

# 20. Adding a New Service

Create a new service when:

- a responsibility is clearly distinct;
- the functionality is reusable;
- the logic interacts with an external system;
- the logic is complex enough to require independent testing;
- keeping it in the current component would reduce maintainability.

Do not create a service merely to move a few lines of trivial code.

A service should have one clear purpose.

---

# 21. Adding a New Model

Create a model when data has:

- multiple fields;
- defined semantics;
- serialization/deserialization;
- repeated use;
- independent validation or transformation.

Prefer structured models over passing untyped maps throughout the application.

---

# 22. Adding a New Widget

Create a reusable widget when:

- a UI component is used more than once;
- a component has meaningful independent behavior;
- a screen becomes too complex;
- a component can be tested or reasoned about independently.

Do not extract every three lines of UI into a separate widget.

The goal is clarity, not maximum fragmentation.

---

# 23. Testing Architecture

Tests should exist at the appropriate layer.

## Models

Test:

- serialization;
- deserialization;
- formatting;
- validation;
- edge cases.

## Services

Test:

- successful responses;
- failures;
- empty results;
- transformations;
- fallback behavior.

## Widgets

Test:

- important rendering states;
- user interactions;
- loading;
- empty states;
- errors.

The project already contains tests for models and services such as `RouteInfo`, `SavedMarker`, `MapTileStyle`, `Place`, and `PlaceDetailsService`.

---

# 24. Error Boundaries

Errors should be handled at the layer that understands them.

Example:

```text
HTTP error
    ↓
Service understands network failure
    ↓
Application layer decides what it means
    ↓
UI displays appropriate state
```

Avoid leaking low-level errors directly into presentation code.

At the same time, do not hide useful diagnostic information.

---

# 25. Performance Boundaries

Performance-sensitive operations should not unnecessarily block UI work.

Pay particular attention to:

- network requests;
- large JSON responses;
- map rendering;
- marker generation;
- image loading;
- repeated rebuilds;
- disk operations;
- expensive calculations.

Optimize based on an actual problem or clear architectural requirement.

Do not sacrifice readability for speculative optimization.

---

# 26. Architecture Rules for AI Agents

When modifying the project, an AI agent must:

1. Inspect the existing architecture first.
2. Reuse existing services and models.
3. Avoid creating duplicate functionality.
4. Keep UI and business logic separated.
5. Keep external API logic inside services.
6. Preserve existing public behavior unless the task requires a change.
7. Avoid unrelated refactoring.
8. Prefer the smallest architectural change that solves the problem.
9. Add tests for meaningful new behavior.
10. Verify the result before reporting completion.

---

# 27. Architectural Red Flags

Stop and reconsider if a change introduces:

```text
Widget
  ↓
HTTP request
```

or:

```text
Widget
  ↓
Database
```

or:

```text
Model
  ↓
Widget
```

or:

```text
One giant service
  ├── search
  ├── routing
  ├── storage
  ├── location
  ├── authentication
  └── unrelated business logic
```

These patterns usually indicate that responsibilities are being mixed.

---

# 28. When Architecture May Be Changed

Architecture can be changed when:

- the current structure prevents the required feature;
- responsibilities are clearly mixed;
- a dependency direction is fundamentally wrong;
- the current design creates a measurable maintenance or reliability problem;
- the project requirements have materially changed.

Architectural changes should be:

- intentional;
- scoped;
- documented when significant;
- tested;
- reviewed separately from unrelated feature work.

Do not perform architectural changes solely for stylistic reasons.

---

# 29. Decision Rule

When deciding where new code belongs, use this order:

```text
Is it UI?
    ↓ yes
Widget

Is it structured data?
    ↓ yes
Model

Is it external communication or reusable business operation?
    ↓ yes
Service

Is it application-level coordination/state?
    ↓ yes
Coordinator / appropriate application layer

Otherwise:
    ↓
Inspect existing architecture before creating a new layer.
```

Do not create a new architectural layer simply because the existing categories are imperfect.

---

# 30. Architectural Goal

The goal of this architecture is not to achieve theoretical purity.

The goal is to make the codebase:

```text
Easy to understand
        ↓
Easy to change
        ↓
Easy to test
        ↓
Hard to accidentally break
```

Every architectural decision should move the project toward these properties.

---

# 31. Source of Truth

`README.md` describes what the project is, its capabilities, setup, and high-level structure.

`ARCHITECTURE.md` describes how the code should be structured and extended.

`AGENTS.md` describes how an AI/software engineering agent should work within the repository.

When modifying the project:

```text
AGENTS.md
    ↓
How to work

ARCHITECTURE.md
    ↓
How to structure code

README.md
    ↓
What the project is and how to use it
```

These documents should complement each other rather than duplicate each other.