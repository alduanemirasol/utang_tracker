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
│   ├── errors/
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
│   └── payments/
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
- Domain Services

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

**Contains**

- SQLite
- sqflite
- Data Sources
- Repository Implementations
- Database Models

**Must Not**

- Business rules
- UI logic

---

### Presentation

**Purpose**

- Handles user interaction.

**Contains**

- Screens
- Widgets
- Controllers
- Riverpod Providers
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

---

## General Rules

- Organize code by feature.
- Keep features independent.
- One entity per file.
- One use case per file.
- One repository interface per entity.
- One repository implementation per repository interface.
- Business logic belongs in the Domain layer.
- Application orchestrates business logic.
- Infrastructure implements interfaces.
- Presentation displays data only.
- Controllers call use cases only.
- Widgets remain reusable.
- Depend on abstractions, not implementations.
- Use dependency injection with Riverpod.
- Avoid circular dependencies.
- Share common code through the `core` module.
