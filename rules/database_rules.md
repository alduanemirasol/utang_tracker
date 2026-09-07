# Database Rules

The application uses Drift with SQLite. The current schema version is `5`.

## Storage Conventions

- IDs are UUID v4 values stored as SQLite `TEXT`.
- Money is stored as integer centavos (`INTEGER`), where 100 centavos equals one peso. Floating-point values are not used for money.
- Quantities are stored as SQLite `REAL` values so fractional quantities are supported.
- Drift `DateTime` values are stored as SQLite `INTEGER` values. Application repositories normalize persisted dates and timestamps to UTC.
- Debt transaction and payment timestamps combine the user-selected local calendar day with the local clock time at save before UTC normalization. Due dates remain date-only selections and do not receive the save time.
- A row is active when `deleted_at IS NULL`.
- Unless noted otherwise, validation and derived-value rules are enforced by the repositories rather than by SQLite `CHECK` or `UNIQUE` constraints.

## Tables

### `customers`

| Column | SQLite type | Nullable | Notes |
| --- | --- | --- | --- |
| `id` | `TEXT` | No | Primary key; UUID v4 |
| `name` | `TEXT` | No | Trimmed, non-empty customer name |
| `phone` | `TEXT` | Yes | Trimmed; an empty value is stored as `NULL` |
| `notes` | `TEXT` | Yes | Trimmed; an empty value is stored as `NULL` |
| `created_at` | `INTEGER` | No | Drift `DateTime`, UTC |
| `updated_at` | `INTEGER` | No | Drift `DateTime`, UTC |
| `deleted_at` | `INTEGER` | Yes | Drift `DateTime`, UTC; `NULL` means active |

### `debts`

| Column | SQLite type | Nullable | Notes |
| --- | --- | --- | --- |
| `id` | `TEXT` | No | Primary key; UUID v4 |
| `customer_id` | `TEXT` | No | Foreign key to `customers.id` |
| `total_amount` | `INTEGER` | No | Total debt amount in centavos |
| `paid_amount` | `INTEGER` | No | Amount paid in centavos |
| `balance` | `INTEGER` | No | Remaining amount in centavos |
| `status` | `TEXT` | No | `UNPAID`, `PARTIAL`, or `PAID` |
| `transaction_date` | `INTEGER` | No | Drift `DateTime`, UTC |
| `due_date` | `INTEGER` | Yes | Drift `DateTime`, UTC |
| `notes` | `TEXT` | Yes | Trimmed; an empty value is stored as `NULL` |
| `created_at` | `INTEGER` | No | Drift `DateTime`, UTC |
| `updated_at` | `INTEGER` | No | Drift `DateTime`, UTC |
| `deleted_at` | `INTEGER` | Yes | Drift `DateTime`, UTC; `NULL` means active |

### `debt_items`

| Column | SQLite type | Nullable | Notes |
| --- | --- | --- | --- |
| `id` | `TEXT` | No | Primary key; UUID v4 |
| `debt_id` | `TEXT` | No | Foreign key to `debts.id` |
| `product_name` | `TEXT` | No | Trimmed, non-empty product name |
| `quantity` | `REAL` | No | Must be greater than zero |
| `unit` | `TEXT` | No | Defaults to `piece`; maximum 24 characters |
| `price` | `INTEGER` | No | Final custom line amount in centavos; must be greater than zero |
| `deleted_at` | `INTEGER` | Yes | Drift `DateTime`, UTC; `NULL` means active |

Common unit values are:

- `piece`
- `pack`
- `box`
- `bottle`
- `kg`
- `g`
- `liter`
- `ml`
- `can`
- `sachet`
- `bag`
- `dozen`
- `tray`
- `bundle`

Common units are normalized case-insensitively to the values above. A trimmed, non-empty custom unit is also allowed. Items that predate unit support migrate to `piece`.

### `payments`

| Column | SQLite type | Nullable | Notes |
| --- | --- | --- | --- |
| `id` | `TEXT` | No | Primary key; UUID v4 |
| `debt_id` | `TEXT` | No | Foreign key to `debts.id` |
| `amount` | `INTEGER` | No | Payment amount in centavos |
| `payment_date` | `INTEGER` | No | Drift `DateTime`, UTC |
| `payment_method` | `TEXT` | No | Trimmed, non-empty value |
| `notes` | `TEXT` | Yes | Trimmed; an empty value is stored as `NULL` |
| `created_at` | `INTEGER` | No | Drift `DateTime`, UTC |
| `deleted_at` | `INTEGER` | Yes | Drift `DateTime`, UTC; `NULL` means active |

## Relationships

- One customer can have many debts: `debts.customer_id` references `customers.id`.
- One debt can have many debt items: `debt_items.debt_id` references `debts.id`.
- One debt can have many payments: `payments.debt_id` references `debts.id`.
- The schema does not define cascading deletes. Related history is retained.

## Indexes

Fresh databases create these indexes:

- `idx_debts_customer_id` on `debts.customer_id`
- `idx_debts_status` on `debts.status`
- `idx_debts_transaction_date` on `debts.transaction_date`
- `idx_debt_items_debt_id` on `debt_items.debt_id`
- `idx_payments_debt_id` on `payments.debt_id`
- `idx_payments_payment_date` on `payments.payment_date`

## Business Rules

### Customers

- Customer names are required and unique among active customers, using a case-insensitive repository check. Soft-deleted names may be reused.
- A customer cannot be deleted while any active, unpaid debt (UNPAID or PARTIAL) exists for that customer.
- Customer deletion is a soft delete that sets `deleted_at` and `updated_at`.

### Debts and debt items

- A debt can be created only for an active customer and must contain at least one valid item.
- `debt_items.price` is the final custom line amount. Quantity does not multiply price.
- `total_amount = sum(active debt item prices)`.
- A new debt starts with `paid_amount = 0`, `balance = total_amount`, and `status = UNPAID`.
- Saving a debt preserves the selected transaction day and stamps it with the current local time.
- A debt is editable only while `paid_amount = 0`.
- Editing a debt is atomic: existing active items are soft-deleted, replacement items are inserted, and the debt totals and dates are updated in the same transaction.

### Payments and debt status

- A payment amount must be greater than zero and cannot exceed the debt's current balance.
- Payments can be recorded only against an active debt that is not already `PAID`.
- Recording a payment preserves the selected payment day and stamps it with the current local time.
- Recording a payment is atomic: the payment is inserted and the debt's `paid_amount`, `balance`, `status`, and `updated_at` are updated in the same transaction.
- `balance = total_amount - paid_amount`.
- Status is derived from the paid amount:
  - `UNPAID` when `paid_amount <= 0`
  - `PARTIAL` when `0 < paid_amount < total_amount`
  - `PAID` when `paid_amount >= total_amount`

## Active-Record Query Behavior

- Customer lists, searches, lookups, and counts include only active customers.
- Debt lists and detail lookups include only active debts whose customer is active; debt items in a detail view must also be active.
- Active-debt counts and outstanding-balance totals include active debts with `UNPAID` or `PARTIAL` status.
- General payment lists include only active payments whose debt and customer are active. Debt-specific payment history filters active payments by debt ID.
- Collected-amount totals include active payments within the requested UTC date range.
- The current repositories expose soft deletion for customers and use soft deletion when replacing debt items. They do not expose debt or payment deletion operations.

## Migration History

- Version 2 added `deleted_at` to all four tables.
- Version 3 recreated the legacy `debt_items` table without its earlier unit column.
- Version 4 added the current `unit` column with a `piece` default.
- Version 5 replaced the legacy `unit_price` and `subtotal` columns with `price`, preserving each existing item's former subtotal as its final custom line amount.

## Backup Audit

- Backup audit log and history are persisted via SharedPreferences JSON — no SQLite table or migration. Entries are append-only and trimmed to the 100 most recent via `BackupLocalDatasource.maxEntries` (applies to both audit log and history).
- **SharedPreferences keys (12 in `lib/features/backup/data/datasources/backup_prefs_keys.dart`):** `backup_audit_log` (audit JSON list), `backup_history` (history JSON list), `backup_last_time_ms` (last successful backup epoch ms), `backup_interval` (Off/Daily/3days/Weekly name), `backup_last_hash` (SHA256 of last zip), `backup_drive_folder_id` (Drive folder `utang_tracker_backup` ID), `backup_next_scheduled_ms` (next auto backup epoch ms), `backup_queued` (bool flag if queue non-empty), `backup_last_size` (last zip size bytes), `backup_queue_json` (JSON queue list), `backup_last_error` (last error message), `backup_auto_enabled` (dead code — written but never read; interval is authoritative).
- **Queue mechanics (`lib/features/backup/data/services/backup_queue_service.dart` + `backup_queue_entry.dart`):** offline/failed backups are enqueued as JSON in `backup_queue_json` with `backup_queued` flag. Max 20 entries (trimmed oldest-first on save); deduplication by type+timestamp key and by guard `type` with `retryCount == 0` plus 5-minute window on same type. 3 retries max — `incrementRetry` bumps `retryCount`, beyond 3 dequeues and logs failure. Exponential backoff via `backoffFor`: 1m (retry 0) → 5m (retry 1) → 30m (retry 2+). JSON persistence through `SharedPreferences`.
- **Scheduler (`lib/features/backup/data/services/backup_scheduler.dart`, `workmanager: ^0.10.9`):** periodic task `utang_auto_backup` (unique name `utang_auto_backup_periodic`) with `NetworkType.connected` constraint. Frequency derived from `BackupInterval.duration` but clamped to minimum 15m. Registered via `BackupScheduler.register(interval)` and initialized in `lib/main.dart` (`Workmanager().initialize(callbackDispatcher)` + `register` on launch). Background entry point is `callbackDispatcher` (`@pragma('vm:entry-point')`).
- **Hash dedup (`crypto: ^3.0.7`):** zip bytes are SHA256-hashed (`sha256.convert(zipBytes).toString()`). Hash stored in `backup_last_hash` and in Drive file `appProperties['sha256']`. Before upload the repository and scheduler compare the new hash against `backup_last_hash` and against `GoogleDriveService.listBackupsInFolder()` hashes — duplicates are skipped with `DuplicateBackupException` / `backup_last_error` message.
