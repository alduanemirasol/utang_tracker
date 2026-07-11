# Database Rules

## Tables

### customers

| Column     | Type     | Required |
| ---------- | -------- | -------- |
| id         | UUID     | Yes      |
| name       | TEXT     | Yes      |
| phone      | TEXT     | No       |
| notes      | TEXT     | No       |
| created_at | DATETIME | Yes      |
| updated_at | DATETIME | Yes      |
| deleted_at | DATETIME | No       |

---

### debts

| Column           | Type          | Required |
| ---------------- | ------------- | -------- |
| id               | UUID          | Yes      |
| customer_id      | UUID          | Yes      |
| total_amount     | DECIMAL(10,2) | Yes      |
| paid_amount      | DECIMAL(10,2) | Yes      |
| balance          | DECIMAL(10,2) | Yes      |
| status           | TEXT          | Yes      |
| transaction_date | DATETIME      | Yes      |
| due_date         | DATETIME      | No       |
| notes            | TEXT          | No       |
| created_at       | DATETIME      | Yes      |
| updated_at       | DATETIME      | Yes      |
| deleted_at       | DATETIME      | No       |

Allowed values for `status`:

- UNPAID
- PARTIAL
- PAID

---

### debt_items

| Column       | Type          | Required |
| ------------ | ------------- | -------- |
| id           | UUID          | Yes      |
| debt_id      | UUID          | Yes      |
| product_name | TEXT          | Yes      |
| quantity     | DECIMAL(10,2) | Yes      |
| unit_price   | DECIMAL(10,2) | Yes      |
| subtotal     | DECIMAL(10,2) | Yes      |
| deleted_at   | DATETIME      | No       |

---

### payments

| Column         | Type          | Required |
| -------------- | ------------- | -------- |
| id             | UUID          | Yes      |
| debt_id        | UUID          | Yes      |
| amount         | DECIMAL(10,2) | Yes      |
| payment_date   | DATETIME      | Yes      |
| payment_method | TEXT          | Yes      |
| notes          | TEXT          | No       |
| created_at     | DATETIME      | Yes      |
| deleted_at     | DATETIME      | No       |

---

## Relationships

- `customers.id` → `debts.customer_id` (1:N)
- `debts.id` → `debt_items.debt_id` (1:N)
- `debts.id` → `payments.debt_id` (1:N)

---

## Business Rules

- One customer can have many debts.
- One debt belongs to one customer.
- One debt can contain many debt items.
- One debt can have multiple payments.
- `subtotal = quantity × unit_price`
- `balance = total_amount - paid_amount`
- Update `paid_amount`, `balance`, and `status` whenever a payment is recorded.
- `due_date` is optional.
- `phone` and `notes` are optional for customers.
- `notes` is optional for debts and payments.
- Soft delete: set `deleted_at` instead of removing rows. Active records have `deleted_at` null.
- Default lists, counts, and aggregates include only active records (`deleted_at` is null).
- Customers with active debts cannot be deleted.
- Customer names must be unique among active customers (case-insensitive).
