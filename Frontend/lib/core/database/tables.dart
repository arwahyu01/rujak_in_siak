import 'package:drift/drift.dart';

class CatalogCategories extends Table {
  TextColumn get uuid => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'catalog_products_category', columns: {#categoryUuid})
class CatalogProducts extends Table {
  TextColumn get uuid => text()();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  IntColumn get price => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get categoryUuid => text().nullable().references(
    CatalogCategories,
    #uuid,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'catalog_variants_product', columns: {#productUuid})
class CatalogVariants extends Table {
  TextColumn get uuid => text()();
  TextColumn get productUuid =>
      text().references(CatalogProducts, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  IntColumn get priceDelta => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'catalog_addons_product', columns: {#productUuid})
class CatalogAddons extends Table {
  TextColumn get uuid => text()();
  TextColumn get productUuid =>
      text().references(CatalogProducts, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get price => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'local_orders_status', columns: {#status})
class LocalOrders extends Table {
  TextColumn get uuid => text()();
  TextColumn get orderNumber => text().nullable()();
  TextColumn get orderType => text().withDefault(const Constant('dine_in'))();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('held'))();
  IntColumn get transactionDiscount =>
      integer().withDefault(const Constant(0))();
  IntColumn get baseVersion => integer().withDefault(const Constant(0))();
  TextColumn get serverUuid => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'order_items_order', columns: {#orderUuid})
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderUuid =>
      text().references(LocalOrders, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get productUuid => text()();
  TextColumn get productName => text()();
  TextColumn get variantUuid => text().nullable()();
  TextColumn get variantName => text().nullable()();
  TextColumn get addonsJson => text().withDefault(const Constant('[]'))();
  IntColumn get unitPrice => integer()();
  IntColumn get quantity => integer()();
  IntColumn get itemDiscount => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBasisPoints =>
      integer().withDefault(const Constant(0))();
  IntColumn get lineSubtotal => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

@TableIndex(name: 'local_sales_transacted', columns: {#transactedAt})
class LocalSales extends Table {
  TextColumn get uuid => text()();
  TextColumn get receiptNumber => text()();
  TextColumn get orderUuid => text().nullable()();
  TextColumn get serverOrderUuid => text().nullable()();
  IntColumn get sourceOrderVersion =>
      integer().withDefault(const Constant(0))();
  TextColumn get origin => text().withDefault(const Constant('online'))();
  TextColumn get orderType => text()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get lifecycleStatus =>
      text().withDefault(const Constant('finalized'))();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();
  IntColumn get subtotal => integer()();
  IntColumn get itemDiscountTotal => integer().withDefault(const Constant(0))();
  IntColumn get transactionDiscountTotal =>
      integer().withDefault(const Constant(0))();
  IntColumn get discountTotal => integer().withDefault(const Constant(0))();
  IntColumn get netSubtotal => integer().withDefault(const Constant(0))();
  IntColumn get serviceCharge => integer().withDefault(const Constant(0))();
  IntColumn get taxTotal => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  IntColumn get confirmedAmount => integer().withDefault(const Constant(0))();
  IntColumn get awaitingAmount => integer().withDefault(const Constant(0))();
  IntColumn get refundedAmount => integer().withDefault(const Constant(0))();
  TextColumn get shiftUuid => text().nullable()();
  TextColumn get cashierName => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get transactedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'sale_items_sale', columns: {#saleUuid})
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleUuid =>
      text().references(LocalSales, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get productUuid => text()();
  TextColumn get productName => text()();
  TextColumn get variantUuid => text().nullable()();
  TextColumn get variantName => text().nullable()();
  TextColumn get addonsJson => text().withDefault(const Constant('[]'))();
  IntColumn get unitPrice => integer()();
  IntColumn get quantity => integer()();
  IntColumn get itemDiscount => integer().withDefault(const Constant(0))();
  IntColumn get lineSubtotal => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}

@TableIndex(name: 'sale_payments_sale', columns: {#saleUuid})
@TableIndex(name: 'sale_payments_uuid', columns: {#paymentUuid})
class SalePayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleUuid =>
      text().references(LocalSales, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get paymentUuid => text().nullable()();
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  IntColumn get tenderedAmount => integer().nullable()();
  IntColumn get changeAmount => integer().nullable()();
  IntColumn get verifiedAmount => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get providerReference => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

@TableIndex(
  name: 'payment_proof_uploads_status',
  columns: {#status, #nextAttemptAt},
)
class PaymentProofUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleUuid => text()();
  TextColumn get paymentUuid => text().unique()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'outbox_status_sequence', columns: {#status, #sequence})
class OutboxEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().unique()();
  TextColumn get eventType => text()();
  TextColumn get aggregateType => text()();
  TextColumn get aggregateId => text()();
  IntColumn get sequence => integer()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  BoolColumn get retryable => boolean().withDefault(const Constant(true))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@TableIndex(name: 'local_shifts_status', columns: {#status})
class LocalShifts extends Table {
  TextColumn get uuid => text()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get openingCash => integer().withDefault(const Constant(0))();
  TextColumn get openingNotes => text().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get expectedCash => integer().nullable()();
  IntColumn get actualCash => integer().nullable()();
  IntColumn get difference => integer().nullable()();
  TextColumn get closingNotes => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get closeEpoch => integer().withDefault(const Constant(0))();
  BoolColumn get isClosing => boolean().withDefault(const Constant(false))();
  TextColumn get openedByName => text().nullable()();
  TextColumn get openedDeviceName => text().nullable()();
  IntColumn get closeActualCash => integer().nullable()();
  TextColumn get closedByName => text().nullable()();
  TextColumn get closedDeviceName => text().nullable()();
  BoolColumn get canFinalize => boolean().withDefault(const Constant(false))();
  TextColumn get pendingDevicesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get serverSummaryJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'cash_movements_shift', columns: {#shiftUuid})
class CashMovements extends Table {
  TextColumn get uuid => text()();
  TextColumn get shiftUuid =>
      text().references(LocalShifts, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uuid};
}

@TableIndex(name: 'print_jobs_status', columns: {#status})
class PrintJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleUuid => text()();
  TextColumn get kind => text().withDefault(const Constant('receipt'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get printedAt => dateTime().nullable()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();
  DateTimeColumn get lastPushedAt => dateTime().nullable()();
  DateTimeColumn get catalogSyncedAt => dateTime().nullable()();
  TextColumn get catalogVersion => text().nullable()();
  TextColumn get lastServerTime => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ReceiptCounters extends Table {
  TextColumn get terminalCode => text()();
  IntColumn get lastSequence => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {terminalCode};
}
