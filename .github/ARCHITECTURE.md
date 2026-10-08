# Architecture Guide for AI Agent

## 1. Overview
The project follows a strict, scale-ready Feature-First Clean Architecture powered by Riverpod for state management and dependency injection. 

The primary goal is to isolate the pure business logic (Domain Layer) from external dependencies, UI frameworks, and data sources (Data & Presentation Layers).

---

## 2. Layer Definitions & Dependency Flow
Dependencies must strictly flow inward toward the Domain Layer. The Domain Layer must be pure Dart and have zero dependencies on any other layer or third-party framework (including Flutter and Riverpod).

┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   [Widgets / UI]  ──>  [Controllers (StateNotifier)]  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                      │
│   [Use Cases] ──> [Entities] ──> [Repository Interface]│
└───────────────────────────▲────────────────────────────┘
                            │ (Implements interface)
                            │
┌───────────────────────────┴────────────────────────────┐
│                       DATA LAYER                       │
│   [Repository Impl] ──> [DataSources] ──> [Data Models]│
└────────────────────────────────────────────────────────┘
---

## 3. Detailed Layer Responsibilities

### A. Domain Layer (The Core)
*   Entities: Pure, immutable Dart classes representing core business concepts. They contain no JSON serialization (fromJson/toJson) and no dependencies on the Flutter framework.
*   Use Cases: Classes encapsulating a single, atomic business operation (e.g., GetSavedMarkersUseCase). They execute business logic and interact exclusively with abstract repository interfaces.
*   Repository Interfaces: Abstract contracts defining data operations. They define *what* the application needs, not *how* it's retrieved.

### B. Data Layer (Infrastructure)
*   Data Models: Subclasses or extensions of Domain Entities that add serialization logic (fromJson, toJson) and local data handling.
*   Data Sources: Execute raw HTTP requests (using Dio/HTTP), platform channels, or cache lookups (SharedPreferences/Isar). They handle timeouts and rotate API mirrors if a failure occurs.
*   Repository Implementations: Concrete classes that implement the Domain Repository interfaces. They orchestrate Data Sources, handle caching strategies, and catch raw network/database exceptions.
*   Error Boundaries: Repositories must catch low-level exceptions and map them into domain-level Failure objects, returning a Result<T> monad (Success or Failure) instead of throwing unhandled exceptions.

### C. Presentation Layer (User Interface)
*   Controllers (Riverpod Notifiers): Manage reactive UI state. They listen to Use Cases, trigger execution, and update the state. They must never communicate with Data Sources or Repositories directly—only through Use Cases.
*   Widgets: Pure UI components (ConsumerWidget or ConsumerStatefulWidget). They render state, capture user actions, and forward them to Controllers via ref.read(). They contain zero business logic.

---

## 4. Project Structure (Feature-First)
The repository is organized by feature packages under lib/features/. Cross-cutting logic lives in lib/core/.
lib/
├── core/                              # Global foundational infrastructure
│   ├── errors/                        # Failures, Exceptions, and Result monad
│   ├── network/                       # Shared HTTP client configurations
│   └── theme/                         # AppTheme and visual design tokens
│
├── features/                          # Domain-driven features
│   ├── markers/                       # Saved pins & bookmark storage
│   │   ├── data/
│   │   │   ├── datasources/           # Local SharedPreferences datasource
│   │   │   ├── models/                # SavedMarkerModel (with JSON serialization)
│   │   │   └── repositories/          # MarkerRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/              # SavedMarker (Pure Dart configuration)
│   │   │   ├── repositories/          # Abstract MarkerRepository interface
│   │   │   └── usecases/              # GetSavedMarkersUseCase, SaveMarkerUseCase
│   │   └── presentation/
│   │       ├── controllers/           # MarkersNotifier (Riverpod AsyncNotifier)
│   │       └── widgets/               # SavedMarkersSheet, MarkerLayerWidget
│   │
│   └── places/                        # POI search and discovery
│       ├── data/                      # Overpass API datasource & failovers
│       ├── domain/                    # Place entity and abstract interfaces
│       └── presentation/              # PlacesNotifier and PlaceDetailsSheet
│
└── main.dart                          # Application bootstrap with ProviderScope
---

## 5. Strict Architecture Rules for AI Agents
When writing code or introducing changes to this codebase, you must strictly adhere to the following guardrails:

1.  No Leaky Dependencies: Do not import package:flutter or presentation files inside the domain/ directory.
2.  Entity Isolation: Entities must remain completely clear of data mapping. All fromJson and toJson methods must live strictly inside data/models/ and extend or map to the respective Entity.
3.  No Direct Data Access from UI: A Widget cannot talk to a Repository or DataSource. A Widget calls a Controller, the Controller executes a Use Case, the Use Case communicates via the Repository interface.
4.  Functional Error Handling: All asynchronous data operations must return a Result<Failure, T> type wrapper. Never let raw database errors or HTTP 500 status codes leak into the UI controllers.
5.  Smallest Architectural Change: Solve features using existing models, parameters, and Use Cases before writing new abstractions from scratch. Prevent redundant duplicates.

---

## 6. Implementation Checklist for New Features
When creating a new feature or sub-feature, implement components in this exact order:
1.  Define the pure Entity class in domain/entities/.
2.  Write the abstract Repository contract in domain/repositories/.
3.  Implement the specialized Use Case(s) in domain/usecases/.
4.  Create the Data Model with JSON serialization methods in data/models/.
5.  Build the concrete DataSource and Repository Implementation in data/.
6.  Bind them using Riverpod Providers, creating the State Controller in presentation/controllers/.
7.  Compose the final UI components and connect them using ref.watch and ref.read.