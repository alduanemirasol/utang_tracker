# Architecture Rules

## Technology Stack

| Category             | Technology         |
| -------------------- | ------------------ |
| Framework            | Flutter            |
| Language             | Dart               |
| Architecture         | Clean Architecture |
| State Management     | Riverpod           |
| Navigation           | GoRouter           |
| Local Database       | SQLite             |
| Database Library     | sqflite            |
| Dependency Injection | Riverpod Providers |
| Linting              | flutter_lints      |

---

## Folder Structure

```text
lib/
├── core/
│   ├── database/
│   │   ├── data_sources/       # Shared data sources (Debt, DebtItem, Payment)
│   │   ├── app_database.dart
│   │   └── tables.dart
│   ├── errors/
│   │   ├── failure.dart
│   │   └── result.dart
│   ├── infrastructure/
│   │   └── models/             # Shared models (DebtModel, DebtItemModel, PaymentModel)
│   ├── presentation/
│   │   └── providers/          # Centralized Riverpod providers
│   ├── extensions/
│   ├── router/
│   ├── services/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── customers/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   ├── debts/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   ├── debt_items/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   ├── payments/
│   │   ├── application/
│   │   ├── domain/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   └── dashboard/
│       ├── application/
│       ├── domain/
│       ├── infrastructure/
│       └── presentation/
│
└── main.dart
```

---

## Layers

### Domain

**Purpose**

- Contains business rules.
- Defines entities and contracts.

**Contains**

- Entities
- Enums
- Repository Interfaces
- Value Objects
- Domain Services (e.g., `DebtCalculator` for pure business logic)

**Must Not**

- Flutter
- Riverpod
- SQLite
- UI
- HTTP
- External services

---

### Application

**Purpose**

- Implements business use cases.
- Orchestrates domain services and repositories.

**Contains**

- Use Cases
- DTOs
- Validators
- Mappers

**Must Not**

- SQLite queries
- Riverpod providers
- Widgets
- Framework-specific code

---

### Infrastructure

**Purpose**

- Implements external dependencies.
- Contains shared data sources and models in `core/infrastructure/`.

**Contains**

- SQLite
- sqflite
- Data Sources (shared ones in `core/database/data_sources/`)
- Repository Implementations
- Database Models (shared ones in `core/infrastructure/models/`)

**Must Not**

- Business rules (use Domain Services instead)
- UI logic

---

### Presentation

**Purpose**

- Handles user interaction.

**Contains**

- Screens
- Widgets
- Controllers
- Riverpod Providers (centralized in `core/presentation/providers/`)
- GoRouter configuration

**Must Not**

- Business logic
- SQL queries

---

## Dependencies

- Presentation → Application
- Infrastructure → Application
- Infrastructure → Domain
- Application → Domain
- Domain → None
- Features → Core (for shared data sources, models, providers)

---

## Core Module Rules

### Shared Data Sources

- Shared data sources belong in `core/database/data_sources/`.
- Data sources used by multiple features must be in core.
- Feature-specific data sources remain in their feature's infrastructure layer.
- Currently shared: `DebtDataSource`, `DebtItemDataSource`, `PaymentDataSource`.

### Shared Models

- Shared models (DTOs) belong in `core/infrastructure/models/`.
- Models used by multiple features must be in core.
- Currently shared: `DebtModel`, `DebtItemModel`, `PaymentModel`.

### Centralized Providers

- All data source providers belong in `core/presentation/providers/data_source_providers.dart`.
- Feature-specific providers remain in their feature's presentation layer.
- Providers call use cases only, never access SQLite directly.

---

## Domain Services

- Use Domain Services for pure business logic calculations.
- Domain Services have zero dependencies on infrastructure.
- Example: `DebtCalculator` handles debt status and balance calculations.
- Domain Services are called by Use Cases or Repository Implementations.

---

## Riverpod Rules

- Providers belong only in the Presentation layer.
- Providers call use cases only.
- Providers never access SQLite directly.
- Use `Provider` for dependency injection.
- Use `Notifier` or `AsyncNotifier` for state management.
- Keep providers focused on a single responsibility.

---

## SQLite Rules

- SQLite code belongs only in the Infrastructure layer.
- Use `sqflite` for database access.
- Execute SQL through data sources only.
- Repository implementations use data sources.
- Return domain entities from repositories.
- Use transactions for multi-table operations.
- Business logic (e.g., debt recalculation) belongs in Domain Services, not data sources.

---

## General Rules

- Organize code by feature.
- Keep features independent (depend on core, not on each other's infrastructure).
- One entity per file.
- One use case per file.
- One repository interface per entity.
- One repository implementation per repository interface.
- Business logic belongs in the Domain layer (Domain Services).
- Application orchestrates business logic.
- Infrastructure implements interfaces.
- Presentation displays data only.
- Controllers call use cases only.
- Widgets remain reusable.
- Depend on abstractions, not implementations.
- Use dependency injection with Riverpod.
- Avoid circular dependencies.
- Share common code through the `core` module.
