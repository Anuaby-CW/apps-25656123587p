import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

@DataClassName('UserRecord')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().unique()();
  TextColumn get displayName => text().nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRecord')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRecord')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  IntColumn get basePrice => integer()();
  IntColumn get hotPrice => integer().nullable()();
  IntColumn get icePrice => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get trackInventory =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isManualBrew => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductFavoriteRecord')
class ProductFavorites extends Table {
  TextColumn get userId => text()();
  TextColumn get productId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, productId};
}

@DataClassName('AddonRecord')
class Addons extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductAddonRecord')
class ProductAddons extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get addonId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BeanRecord')
class Beans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get hotPrice => integer()();
  IntColumn get icePrice => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ManualBrewMethodRecord')
class ManualBrewMethods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('InventoryRecord')
class Inventory extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().unique()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CustomerRecord')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CafeTableRecord')
class CafeTables extends Table {
  TextColumn get id => text()();
  TextColumn get tableNumber => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderRecord')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get orderNumber => text().unique()();
  TextColumn get cashierUserId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get orderType => text()();
  TextColumn get orderStatus => text()();
  TextColumn get paymentStatus => text()();
  IntColumn get subtotal => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get tax => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderItemRecord')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get productNameSnapshot => text()();
  TextColumn get categoryNameSnapshot => text()();
  IntColumn get unitPrice => integer()();
  IntColumn get quantity => integer()();
  IntColumn get subtotal => integer()();
  TextColumn get temperatureOption => text().nullable()();
  TextColumn get sugarOption => text().nullable()();
  TextColumn get manualBrewMethodNameSnapshot => text().nullable()();
  TextColumn get beanNameSnapshot => text().nullable()();
  TextColumn get addonsJson => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PaymentRecord')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get cashierUserId => text()();
  TextColumn get paymentMethod => text()();
  IntColumn get amountPaid => integer()();
  IntColumn get changeAmount => integer()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get transactionNumber => text().unique()();
  TextColumn get orderId => text()();
  TextColumn get paymentId => text()();
  TextColumn get cashierUserId => text()();
  IntColumn get total => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StockMovementRecord')
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get type => text()();
  IntColumn get quantityChange => integer()();
  IntColumn get quantityAfter => integer()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AuditLogRecord')
class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get actorUserId => text().nullable()();
  TextColumn get actorUsername => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get description => text()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PrinterLogRecord')
class PrinterLogs extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get printerName => text().nullable()();
  TextColumn get printerAddress => text().nullable()();
  TextColumn get status => text()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingRecord')
class Settings extends Table {
  TextColumn get id => text()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PrinterSettingRecord')
class PrinterSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get printerName => text().nullable()();
  TextColumn get printerAddress => text().nullable()();
  TextColumn get printerType =>
      text().withDefault(const Constant('bluetooth'))();
  TextColumn get paperSize => text().withDefault(const Constant('mm58'))();
  BoolColumn get isCashDrawerEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get lastConnectionStatus =>
      text().withDefault(const Constant('disconnected'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PettyCashRecord')
class PettyCash extends Table {
  TextColumn get id => text()();
  IntColumn get amount => integer()();
  TextColumn get notes => text()();
  TextColumn get cashierUserId => text()();
  TextColumn get cashierName => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Users,
    Categories,
    Products,
    ProductFavorites,
    Addons,
    ProductAddons,
    Beans,
    ManualBrewMethods,
    Inventory,
    Customers,
    CafeTables,
    Orders,
    OrderItems,
    Payments,
    Transactions,
    StockMovements,
    AuditLogs,
    PrinterLogs,
    Settings,
    PrinterSettings,
    PettyCash,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: AppConstants.databaseName));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(auditLogs);
        await migrator.createTable(printerLogs);
      }
      if (from < 3) {
        await migrator.createTable(productFavorites);
      }
      if (from < 4) {
        await migrator.addColumn(users, users.displayName);
      }
      if (from < 5) {
        await migrator.createTable(pettyCash);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

extension UserRecordIdentity on UserRecord {
  String get cashierName {
    final value = displayName?.trim();
    return value == null || value.isEmpty ? username : value;
  }
}
