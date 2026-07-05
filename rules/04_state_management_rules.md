# Riverpod Rules

- Use Riverpod for dependency injection.
- Use AsyncNotifier for asynchronous state.
- Use Notifier for synchronous state.
- Do not place business logic inside providers.
- Providers call use cases only.
- Providers never access SQLite directly.
- Keep providers feature scoped.
