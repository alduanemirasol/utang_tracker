# SQLite Rules

- Use sqflite.
- One table per migration.
- Use transactions for write operations.
- Never execute SQL from the UI.
- Never execute SQL from providers.
- Repository implementations communicate with data sources.
- Return domain entities from repositories.
