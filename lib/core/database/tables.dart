const String tableCustomers = 'customers';
const String tableDebts = 'debts';
const String tableDebtItems = 'debt_items';
const String tablePayments = 'payments';

const String columnId = 'id';
const String columnCreatedAt = 'created_at';
const String columnUpdatedAt = 'updated_at';
const String columnDeletedAt = 'deleted_at';

const String columnName = 'name';
const String columnPhone = 'phone';
const String columnNotes = 'notes';

const String columnCustomerId = 'customer_id';
const String columnTotalAmount = 'total_amount';
const String columnPaidAmount = 'paid_amount';
const String columnBalance = 'balance';
const String columnStatus = 'status';
const String columnTransactionDate = 'transaction_date';
const String columnDueDate = 'due_date';

const String columnDebtId = 'debt_id';
const String columnProductName = 'product_name';
const String columnQuantity = 'quantity';
const String columnUnit = 'unit';
const String columnUnitPrice = 'unit_price';
const String columnSubtotal = 'subtotal';

const String columnAmount = 'amount';
const String columnPaymentDate = 'payment_date';
const String columnPaymentMethod = 'payment_method';

const String createCustomersTable = '''
  CREATE TABLE $tableCustomers (
    $columnId TEXT PRIMARY KEY,
    $columnName TEXT NOT NULL,
    $columnPhone TEXT,
    $columnNotes TEXT,
    $columnCreatedAt TEXT NOT NULL,
    $columnUpdatedAt TEXT NOT NULL,
    $columnDeletedAt TEXT
  )
''';

const String createDebtsTable = '''
  CREATE TABLE $tableDebts (
    $columnId TEXT PRIMARY KEY,
    $columnCustomerId TEXT NOT NULL,
    $columnTotalAmount REAL NOT NULL,
    $columnPaidAmount REAL NOT NULL,
    $columnBalance REAL NOT NULL,
    $columnStatus TEXT NOT NULL,
    $columnTransactionDate TEXT NOT NULL,
    $columnDueDate TEXT,
    $columnNotes TEXT,
    $columnCreatedAt TEXT NOT NULL,
    $columnUpdatedAt TEXT NOT NULL,
    $columnDeletedAt TEXT,
    FOREIGN KEY ($columnCustomerId) REFERENCES $tableCustomers($columnId)
  )
''';

const String createDebtItemsTable = '''
  CREATE TABLE $tableDebtItems (
    $columnId TEXT PRIMARY KEY,
    $columnDebtId TEXT NOT NULL,
    $columnProductName TEXT NOT NULL,
    $columnQuantity REAL NOT NULL,
    $columnUnit TEXT NOT NULL,
    $columnUnitPrice REAL NOT NULL,
    $columnSubtotal REAL NOT NULL,
    $columnCreatedAt TEXT,
    $columnDeletedAt TEXT,
    FOREIGN KEY ($columnDebtId) REFERENCES $tableDebts($columnId)
  )
''';

const String createPaymentsTable = '''
  CREATE TABLE $tablePayments (
    $columnId TEXT PRIMARY KEY,
    $columnDebtId TEXT NOT NULL,
    $columnAmount REAL NOT NULL,
    $columnPaymentDate TEXT NOT NULL,
    $columnPaymentMethod TEXT NOT NULL,
    $columnNotes TEXT,
    $columnCreatedAt TEXT NOT NULL,
    $columnDeletedAt TEXT,
    FOREIGN KEY ($columnDebtId) REFERENCES $tableDebts($columnId)
  )
''';

const List<String> allCreateStatements = [
  createCustomersTable,
  createDebtsTable,
  createDebtItemsTable,
  createPaymentsTable,
];

const String alterCustomersAddDeletedAt =
    'ALTER TABLE $tableCustomers ADD COLUMN $columnDeletedAt TEXT';

const String alterDebtsAddDeletedAt =
    'ALTER TABLE $tableDebts ADD COLUMN $columnDeletedAt TEXT';

const String alterDebtItemsAddDeletedAt =
    'ALTER TABLE $tableDebtItems ADD COLUMN $columnDeletedAt TEXT';

const String alterPaymentsAddDeletedAt =
    'ALTER TABLE $tablePayments ADD COLUMN $columnDeletedAt TEXT';

const List<String> migrationStatementsV2 = [
  alterCustomersAddDeletedAt,
  alterDebtsAddDeletedAt,
  alterDebtItemsAddDeletedAt,
  alterPaymentsAddDeletedAt,
];

const String alterDebtItemsAddCreatedAt =
    'ALTER TABLE $tableDebtItems ADD COLUMN $columnCreatedAt TEXT';

const String backfillDebtItemsCreatedAt = '''
  UPDATE $tableDebtItems
  SET $columnCreatedAt = (
    SELECT d.$columnTransactionDate
    FROM $tableDebts d
    WHERE d.$columnId = $tableDebtItems.$columnDebtId
  )
  WHERE $columnCreatedAt IS NULL
''';

const List<String> migrationStatementsV3 = [
  alterDebtItemsAddCreatedAt,
  backfillDebtItemsCreatedAt,
];
