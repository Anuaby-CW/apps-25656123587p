import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/core/config/feature_flags.dart';
import 'package:talaga_coffee_pos/core/permissions/bluetooth_permission_service.dart';
import 'package:talaga_coffee_pos/core/printer/android_bluetooth_printer_service.dart';
import 'package:talaga_coffee_pos/core/printer/cash_drawer_service.dart';
import 'package:talaga_coffee_pos/core/files/report_file_saver.dart';
import 'package:talaga_coffee_pos/core/printer/printer_service.dart';
import 'package:talaga_coffee_pos/core/routing/app_destination.dart';
import 'package:talaga_coffee_pos/core/utils/date_formatter.dart';
import 'package:talaga_coffee_pos/core/utils/idr_amount_input_formatter.dart';
import 'package:talaga_coffee_pos/core/utils/locale_bootstrap.dart';
import 'package:talaga_coffee_pos/core/utils/money_formatter.dart';
import 'package:talaga_coffee_pos/data/database/app_database.dart';
import 'package:talaga_coffee_pos/data/database/daos/audit_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/catalog_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/orders_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/printer_log_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/reports_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/reset_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/settings_dao.dart';
import 'package:talaga_coffee_pos/data/database/daos/users_dao.dart';
import 'package:talaga_coffee_pos/data/database/seed_data.dart';
import 'package:talaga_coffee_pos/data/repositories/audit_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/auth_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/catalog_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/orders_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/printer_log_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/reports_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/reset_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/checkout_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/settings_repository.dart';
import 'package:talaga_coffee_pos/data/repositories/user_repository.dart';
import 'package:talaga_coffee_pos/domain/models/cart_models.dart';
import 'package:talaga_coffee_pos/domain/models/checkout_models.dart';
import 'package:talaga_coffee_pos/domain/models/enums.dart';
import 'package:talaga_coffee_pos/domain/models/receipt_models.dart';
import 'package:talaga_coffee_pos/domain/models/report_models.dart';
import 'package:talaga_coffee_pos/domain/usecases/checkout_usecase.dart';
import 'package:talaga_coffee_pos/domain/usecases/manual_brew_pricing.dart';
import 'package:talaga_coffee_pos/domain/usecases/receive_payment_usecase.dart';
import 'package:talaga_coffee_pos/domain/usecases/report_export_usecase.dart';
import 'package:talaga_coffee_pos/presentation/providers/app_providers.dart';

void main() {
  setUpAll(LocaleBootstrap.ensureInitialized);

  test(
    'Indonesian date and currency formatters work after locale bootstrap',
    () {
      final formattedDate = DateFormatter.human(DateTime(2026, 8, 9, 13, 5));
      final formattedMoney = MoneyFormatter.format(12500);

      expect(formattedDate, contains('Agu'));
      expect(formattedMoney, contains('Rp'));
      expect(formattedMoney, contains('12.500'));
    },
  );

  test('IDR amount input groups digits and builds quick cash values', () {
    const formatter = IdrAmountInputFormatter();
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '50000',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );

    expect(formatted.text, '50.000');
    expect(formatted.selection.baseOffset, 6);
    expect(IdrAmountInputFormatter.parse('Rp 1.250.000'), 1250000);
    expect(quickCashAmounts(37500), [37500, 40000, 50000, 100000]);
  });

  test('database v2 migrates additively through petty cash schema', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('''
              CREATE TABLE users (
                id TEXT NOT NULL PRIMARY KEY,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                role TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                last_login_at INTEGER
              )
            ''');
          rawDatabase.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(database.close);

    expect(await database.select(database.productFavorites).get(), isEmpty);
    final userColumns = await database
        .customSelect('PRAGMA table_info(users)')
        .get();
    expect(
      userColumns.map((row) => row.read<String>('name')),
      contains('display_name'),
    );
    expect(await database.select(database.pettyCash).get(), isEmpty);
    final versionRow = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(versionRow.read<int>('user_version'), 5);
  });

  test(
    'cashier display name persists without changing login username',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final usersDao = UsersDao(database);
      final repository = UserRepository(usersDao);

      await repository.createUser(
        username: 'kasir.shift1',
        password: 'password',
        role: UserRole.cashier,
      );
      final original = await usersDao.findByUsername('kasir.shift1');
      final updated = await repository.updateDisplayName(original!, '  Andi  ');
      final persisted = await usersDao.findByUsername('kasir.shift1');

      expect(original.cashierName, 'kasir.shift1');
      expect(updated.cashierName, 'Andi');
      expect(persisted?.cashierName, 'Andi');
      expect(persisted?.username, 'kasir.shift1');
    },
  );

  test(
    'seed v1 category labels are localized without replacing data',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.now();
      await database
          .into(database.settings)
          .insert(
            SettingsCompanion.insert(
              id: 'setting_seed_version',
              key: 'seed_version',
              value: '1',
            ),
          );
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'legacy_signature',
              name: 'Signature',
              type: 'drink',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await SeedData(database).ensureSeeded();

      final category = await database.select(database.categories).getSingle();
      final seedVersion = await (database.select(
        database.settings,
      )..where((row) => row.key.equals('seed_version'))).getSingle();
      final instagram = await (database.select(
        database.settings,
      )..where((row) => row.key.equals('outlet_instagram'))).getSingle();
      expect(category.name, 'Menu Andalan');
      expect(seedVersion.value, '2');
      expect(instagram.value, '@talagacoffee');
    },
  );

  test('existing database receives missing Instagram outlet setting', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.settings)
        .insert(
          SettingsCompanion.insert(
            id: 'setting_seed_version',
            key: 'seed_version',
            value: '2',
          ),
        );

    await SeedData(database).ensureSeeded();

    final instagram = await (database.select(
      database.settings,
    )..where((row) => row.key.equals('outlet_instagram'))).getSingle();
    expect(instagram.value, '@talagacoffee');
  });

  test('default admin and kasir login with hashed local passwords', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);

    final admin = await harness.auth.login('admin', '123456');
    final cashier = await harness.auth.login('kasir', '123456');

    expect(admin.role, UserRole.admin.name);
    expect(cashier.role, UserRole.cashier.name);
    expect(admin.passwordHash, isNot('123456'));
  });

  test('role destinations separate cashier operations from admin tools', () {
    expect(AppDestination.forRole(UserRole.cashier), [
      AppDestination.pos,
      if (FeatureFlags.ordersQueue) AppDestination.orders,
      AppDestination.settings,
    ]);
    final adminDestinations = AppDestination.forRole(UserRole.admin);
    expect(adminDestinations, contains(AppDestination.dashboard));
    expect(
      adminDestinations.contains(AppDestination.pos),
      FeatureFlags.adminPosAccess,
    );
    expect(
      AppDestination.initialForRole(UserRole.admin),
      AppDestination.dashboard,
    );
  });

  test(
    'partial legacy shift is recovered instead of locking every cashier',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final settings = SettingsDao(harness.database);
      await settings.upsert('shift_active', 'true');
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(harness.database)],
      );
      addTearDown(container.dispose);

      final shift = await container.read(shiftControllerProvider.future);

      expect(shift.isActive, isFalse);
      expect(await settings.value('shift_active'), 'false');
    },
  );

  test('shift persists the trimmed cashier name used on receipts', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(harness.database)],
    );
    addTearDown(container.dispose);
    await container.read(shiftControllerProvider.future);

    await container
        .read(shiftControllerProvider.notifier)
        .openShift(
          cashierId: 'user_kasir',
          cashierName: '  Andi Pagi  ',
          openingCash: 100000,
        );

    final shift = container.read(shiftControllerProvider).value;
    final settings = SettingsDao(harness.database);
    expect(shift?.cashierName, 'Andi Pagi');
    expect(await settings.value('shift_cashier_name'), 'Andi Pagi');
  });

  test('shift rejects an empty cashier name', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(harness.database)],
    );
    addTearDown(container.dispose);
    await container.read(shiftControllerProvider.future);

    await expectLater(
      container
          .read(shiftControllerProvider.notifier)
          .openShift(
            cashierId: 'user_kasir',
            cashierName: '   ',
            openingCash: 100000,
          ),
      throwsStateError,
    );
  });

  test(
    'Product CRUD creates inventory row and audit log for new product',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final snapshot = await harness.catalog.snapshot(activeOnly: false);
      final category = snapshot.categories.firstWhere(
        (row) => row.parentId != null && row.isActive,
      );

      await harness.catalog.saveProduct(
        name: 'Test Cold Brew',
        categoryId: category.id,
        basePrice: 21000,
        hotPrice: 21000,
        icePrice: 23000,
        trackInventory: true,
        initialStock: 12,
        lowStockThreshold: 3,
        actorUserId: 'user_admin',
        actorUsername: 'admin',
      );

      final updated = await harness.catalog.snapshot(activeOnly: false);
      final product = updated.products.firstWhere(
        (row) => row.name == 'Test Cold Brew',
      );
      final inventory = updated.inventoryByProductId[product.id];
      final audits = await harness.audit.recent();

      expect(inventory, isNotNull);
      expect(inventory!.quantity, 12);
      expect(inventory.lowStockThreshold, 3);
      expect(audits.any((row) => row.action == 'product.create'), isTrue);
    },
  );

  test('Product favorites persist per user and can be removed', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();

    await harness.catalog.setProductFavorite(
      userId: 'user_admin',
      productId: item.productId,
      isFavorite: true,
    );

    expect(
      await harness.catalog.watchFavoriteProductIds('user_admin').first,
      contains(item.productId),
    );
    expect(
      await harness.catalog.watchFavoriteProductIds('user_kasir').first,
      isEmpty,
    );

    await harness.catalog.setProductFavorite(
      userId: 'user_admin',
      productId: item.productId,
      isFavorite: false,
    );
    expect(
      await harness.catalog.watchFavoriteProductIds('user_admin').first,
      isEmpty,
    );
  });

  test('Inventory adjustment writes stock movement and audit log', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();

    await harness.catalog.adjustInventory(
      productId: item.productId,
      quantityAfter: 77,
      type: 'restock',
      notes: 'Test restock',
      actorUserId: 'user_admin',
      actorUsername: 'admin',
    );

    final movements = await harness.catalog.stockMovementsForProduct(
      item.productId,
    );
    final audits = await harness.audit.recent();

    expect(movements.first.type, 'restock');
    expect(movements.first.quantityAfter, 77);
    expect(audits.any((row) => row.action == 'inventory.adjust'), isTrue);
  });

  test('admin can set a per-product low stock threshold', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();
    final initial = await harness.catalog.snapshot(activeOnly: false);
    final inventory = initial.inventoryByProductId[item.productId]!;

    final movementsBefore = await harness.catalog.stockMovementsForProduct(
      item.productId,
    );
    const customThreshold = 17;
    await harness.catalog.adjustInventory(
      productId: item.productId,
      quantityAfter: inventory.quantity,
      lowStockThreshold: customThreshold,
      type: 'correction',
    );
    final updated = await harness.catalog.snapshot(activeOnly: false);
    final updatedInventory = updated.inventoryByProductId[item.productId]!;
    final movementsAfter = await harness.catalog.stockMovementsForProduct(
      item.productId,
    );
    final audits = await harness.audit.recent();

    expect(updatedInventory.quantity, inventory.quantity);
    expect(updatedInventory.lowStockThreshold, customThreshold);
    expect(movementsAfter.length, movementsBefore.length);
    expect(
      audits.any((row) => row.action == 'inventory.threshold.update'),
      isTrue,
    );

    await harness.catalog.adjustInventory(
      productId: item.productId,
      quantityAfter: customThreshold,
      lowStockThreshold: customThreshold,
      type: 'test_low_stock',
    );
    final low = await harness.catalog.snapshot(activeOnly: false);
    expect(
      low.lowStockInventory.map((row) => row.productId),
      contains(item.productId),
    );

    await harness.catalog.adjustInventory(
      productId: item.productId,
      quantityAfter: customThreshold,
      lowStockThreshold: customThreshold - 1,
      type: 'correction',
    );
    final safe = await harness.catalog.snapshot(activeOnly: false);
    expect(
      safe.lowStockInventory.map((row) => row.productId),
      isNot(contains(item.productId)),
    );

    await expectLater(
      harness.catalog.adjustInventory(
        productId: item.productId,
        quantityAfter: customThreshold,
        lowStockThreshold: -1,
        type: 'correction',
      ),
      throwsStateError,
    );
    final afterRejected = await harness.catalog.snapshot(activeOnly: false);
    expect(
      afterRejected.inventoryByProductId[item.productId]!.lowStockThreshold,
      customThreshold - 1,
    );
  });

  test('checkout keeps the custom low stock threshold', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();
    final initial = await harness.catalog.snapshot(activeOnly: false);
    final inventory = initial.inventoryByProductId[item.productId]!;

    await harness.catalog.adjustInventory(
      productId: item.productId,
      quantityAfter: inventory.quantity,
      lowStockThreshold: 19,
      type: 'correction',
    );
    await harness.checkout(
      CheckoutRequest(
        cashierUserId: 'user_kasir',
        cashierName: 'kasir',
        items: [item],
        orderType: OrderType.dineIn,
        customerName: 'Pelanggan',
        tableNumber: 'A01',
        payNow: true,
        amountPaid: 50000,
      ),
    );

    final afterCheckout = await harness.catalog.snapshot(activeOnly: false);
    final current = afterCheckout.inventoryByProductId[item.productId]!;
    expect(current.quantity, inventory.quantity - 1);
    expect(current.lowStockThreshold, 19);
  });

  test(
    'manual brew price comes from selected bean and Hot/Ice option',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);

      final snapshot = await harness.catalog.snapshot();
      final bean = snapshot.beans.firstWhere((row) => row.id == 'bean_wine');

      expect(
        ManualBrewPricing.priceForBean(
          hotPrice: bean.hotPrice,
          icePrice: bean.icePrice,
          temperature: 'Hot',
        ),
        bean.hotPrice,
      );
      expect(
        ManualBrewPricing.priceForBean(
          hotPrice: bean.hotPrice,
          icePrice: bean.icePrice,
          temperature: 'Ice',
        ),
        bean.icePrice,
      );
    },
  );

  test('Cart controller updates inline item options and notes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = CartItem(
      lineId: 'line_test',
      productId: 'prod_test',
      productName: 'Test Latte',
      categoryName: 'Coffee',
      unitPrice: 18000,
      quantity: 2,
      temperatureOption: 'Hot',
      sugarOption: 'Normal Sugar',
      notes: 'Old note',
      trackInventory: true,
    );

    final controller = container.read(cartControllerProvider.notifier);
    controller.add(item);
    controller.updateTemperatureOption(item.lineId, 'Ice', unitPrice: 20000);
    controller.updateSugarOption(item.lineId, 'Less Sugar');
    controller.updateNotes(item.lineId, 'less ice ');

    final edited = container.read(cartControllerProvider).items.single;
    expect(edited.notes, 'less ice ');

    controller.updateNotes(item.lineId, '');

    final updated = container.read(cartControllerProvider).items.single;
    expect(updated.temperatureOption, 'Ice');
    expect(updated.sugarOption, 'Less Sugar');
    expect(updated.unitPrice, 20000);
    expect(updated.notes, isNull);
    expect(updated.subtotal, 40000);
  });

  test(
    'Pay Now creates order, payment, transaction, and prints receipt',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      harness.printer.statusValue = PrinterConnectionStatus.connected;
      await harness.settings.savePrinter(cashDrawerEnabled: true);

      final item = await harness.seedCartItem();
      final result = await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_admin',
          cashierName: 'admin',
          items: [item],
          orderType: OrderType.dineIn,
          customerName: 'Pelanggan',
          tableNumber: 'A01',
          payNow: true,
          amountPaid: 50000,
        ),
      );

      final detail = await harness.orders.detail(result.orderId);
      expect(result.paymentStatus, PaymentStatus.paid);
      expect(detail.payment, isNotNull);
      expect(detail.transaction, isNotNull);
      expect(harness.printer.printReceiptCalls, 1);
      expect(harness.printer.lastReceipt?.cashierName, 'admin');
      expect(harness.printer.lastReceipt?.outletInstagram, '@talagacoffee');
    },
  );

  test('Pay Later follows its feature flag', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    harness.printer.statusValue = PrinterConnectionStatus.connected;

    final item = await harness.seedCartItem();
    final request = CheckoutRequest(
      cashierUserId: 'user_kasir',
      cashierName: 'kasir',
      items: [item],
      orderType: OrderType.takeAway,
      customerName: 'Pelanggan',
      payNow: false,
    );

    if (!FeatureFlags.payLater) {
      await expectLater(
        harness.checkout(request),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Bayar Nanti sedang dinonaktifkan',
          ),
        ),
      );

      final report = await harness.todayReport();
      expect(await harness.orders.watchOrders().first, isEmpty);
      expect(harness.printer.printReceiptCalls, 0);
      expect(report.totalRevenue, 0);
      expect(report.unpaidOrderCount, 0);
    } else {
      final result = await harness.checkout(request);
      final detail = await harness.orders.detail(result.orderId);
      final report = await harness.todayReport();
      expect(result.paymentStatus, PaymentStatus.unpaid);
      expect(detail.payment, isNull);
      expect(detail.transaction, isNull);
      expect(harness.printer.printReceiptCalls, 0);
      expect(report.totalRevenue, 0);
      expect(report.unpaidOrderCount, 1);
    }
  });

  test('checkout requires customer name for Take Away', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();

    await expectLater(
      harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.takeAway,
          payNow: false,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Nama pelanggan wajib diisi',
        ),
      ),
    );
    expect(await harness.orders.watchOrders().first, isEmpty);
  });

  test('Dine In table validation follows its feature flag', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    harness.printer.statusValue = PrinterConnectionStatus.connected;
    final item = await harness.seedCartItem();

    final request = CheckoutRequest(
      cashierUserId: 'user_kasir',
      cashierName: 'kasir',
      items: [item],
      orderType: OrderType.dineIn,
      customerName: 'Pelanggan',
      payNow: true,
      amountPaid: 50000,
    );

    if (FeatureFlags.tableNumber) {
      await expectLater(
        harness.checkout(request),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Nomor meja wajib diisi untuk pesanan Dine In',
          ),
        ),
      );
      expect(await harness.orders.watchOrders().first, isEmpty);
    } else {
      final result = await harness.checkout(request);
      final detail = await harness.orders.detail(result.orderId);
      expect(result.paymentStatus, PaymentStatus.paid);
      expect(detail.order.tableNumber, isNull);
    }
  });

  test(
    'Pay Now opens enabled cash drawer after print when there is change',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      harness.printer.statusValue = PrinterConnectionStatus.connected;
      await harness.settings.savePrinter(cashDrawerEnabled: true);

      final item = await harness.seedCartItem();
      final result = await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.dineIn,
          customerName: 'Pelanggan',
          tableNumber: 'A01',
          payNow: true,
          amountPaid: item.subtotal + 10000,
        ),
      );

      expect(harness.printer.printReceiptCalls, 1);
      expect(harness.printer.openCashDrawerCalls, 1);
      expect(result.cashDrawerAttempted, isTrue);
      expect(result.cashDrawerOpened, isTrue);
      expect(result.cashDrawerError, isNull);
      final logs = await harness.database
          .select(harness.database.printerLogs)
          .get();
      expect(
        logs.any(
          (log) =>
              log.eventType == 'cash_drawer_checkout' &&
              log.status == 'success',
        ),
        isTrue,
      );
    },
  );

  test('Pay Now reports and logs a cash drawer failure', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    harness.printer
      ..statusValue = PrinterConnectionStatus.connected
      ..cashDrawerResult = false;
    await harness.settings.savePrinter(cashDrawerEnabled: true);

    final item = await harness.seedCartItem();
    final result = await harness.checkout(
      CheckoutRequest(
        cashierUserId: 'user_kasir',
        cashierName: 'kasir',
        items: [item],
        orderType: OrderType.takeAway,
        customerName: 'Pelanggan',
        payNow: true,
        amountPaid: item.subtotal + 10000,
      ),
    );

    expect(result.paymentStatus, PaymentStatus.paid);
    expect(result.cashDrawerAttempted, isTrue);
    expect(result.cashDrawerOpened, isFalse);
    expect(result.cashDrawerError, contains('tidak berhasil terbuka'));
    final logs = await harness.database
        .select(harness.database.printerLogs)
        .get();
    expect(
      logs.any(
        (log) =>
            log.eventType == 'cash_drawer_checkout' && log.status == 'failed',
      ),
      isTrue,
    );
  });

  test('Pay Now keeps cash drawer closed when payment has no change', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    harness.printer.statusValue = PrinterConnectionStatus.connected;
    await harness.settings.savePrinter(cashDrawerEnabled: true);

    final item = await harness.seedCartItem();
    await harness.checkout(
      CheckoutRequest(
        cashierUserId: 'user_kasir',
        cashierName: 'kasir',
        items: [item],
        orderType: OrderType.dineIn,
        customerName: 'Pelanggan',
        tableNumber: 'A01',
        payNow: true,
        amountPaid: item.subtotal,
      ),
    );

    expect(harness.printer.printReceiptCalls, 1);
    expect(harness.printer.openCashDrawerCalls, 0);
  });

  test(
    'Reports only include paid orders',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final item = await harness.seedCartItem();

      await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.takeAway,
          customerName: 'Pelanggan',
          payNow: false,
        ),
      );
      expect((await harness.todayReport()).productQuantities, isEmpty);

      await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_admin',
          cashierName: 'admin',
          items: [item.copyWith(quantity: 2)],
          orderType: OrderType.dineIn,
          customerName: 'Pelanggan',
          tableNumber: 'A01',
          payNow: true,
          amountPaid: 100000,
        ),
      );
      final report = await harness.todayReport();
      expect(report.productQuantities[item.productName], 2);
    },
    skip: !FeatureFlags.payLater ? 'Requires FEATURE_PAY_LATER=true.' : false,
  );

  test(
    'report export creates a PDF and delegates it to Downloads saver',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final item = await harness.seedCartItem();
      await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_admin',
          cashierName: 'admin',
          items: [item],
          orderType: OrderType.dineIn,
          customerName: 'Pelanggan',
          tableNumber: 'A01',
          payNow: true,
          amountPaid: 50000,
        ),
      );
      final saver = FakeReportFileSaver();
      final exporter = ReportExportUseCase(
        reportsRepository: harness.reports,
        fileSaver: saver,
        auditRepository: harness.audit,
      );
      final range = ReportRange.today(DateTime.now());

      final result = await exporter.exportPdf(
        range,
        actorUserId: 'user_admin',
        actorUsername: 'admin',
      );

      expect(result.fileName, endsWith('.pdf'));
      expect(result.location, startsWith('content://downloads/'));
      expect(saver.savedFileName, result.fileName);
      expect(String.fromCharCodes(saver.savedBytes!.take(4)), '%PDF');
      final audits = await harness.audit.recent();
      expect(audits.any((row) => row.action == 'report.export'), isTrue);
    },
  );

  test(
    'Receive Payment creates payment, transaction, and prints receipt',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      harness.printer.statusValue = PrinterConnectionStatus.connected;
      await harness.settings.savePrinter(cashDrawerEnabled: true);

      final item = await harness.seedCartItem();
      final unpaid = await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.dineIn,
          customerName: 'Pelanggan',
          tableNumber: 'A01',
          payNow: false,
        ),
      );

      final paid = await harness.receivePayment(
        ReceivePaymentRequest(
          orderId: unpaid.orderId,
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          amountPaid: 50000,
        ),
      );
      final detail = await harness.orders.detail(unpaid.orderId);

      expect(paid.paymentStatus, PaymentStatus.paid);
      expect(detail.payment, isNotNull);
      expect(detail.transaction, isNotNull);
      expect(harness.printer.printReceiptCalls, 1);
      expect(harness.printer.openCashDrawerCalls, 1);
    },
    skip: !FeatureFlags.payLater ? 'Requires FEATURE_PAY_LATER=true.' : false,
  );

  test(
    'cancelling an unpaid order restores stock and blocks later payment',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final item = await harness.seedCartItem();
      final initialSnapshot = await harness.catalog.snapshot(activeOnly: false);
      final initialQuantity =
          initialSnapshot.inventoryByProductId[item.productId]!.quantity;

      final unpaid = await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.takeAway,
          customerName: 'Pelanggan',
          payNow: false,
        ),
      );
      expect(
        (await harness.catalog.snapshot(
          activeOnly: false,
        )).inventoryByProductId[item.productId]!.quantity,
        initialQuantity - 1,
      );

      await harness.orders.cancel(unpaid.orderId);

      final restored = await harness.catalog.snapshot(activeOnly: false);
      final movements = await harness.catalog.stockMovementsForProduct(
        item.productId,
      );
      final report = await harness.todayReport();
      expect(
        restored.inventoryByProductId[item.productId]!.quantity,
        initialQuantity,
      );
      expect(movements.any((row) => row.type == 'sale_reversal'), isTrue);
      expect(report.unpaidOrderCount, 0);
      expect(report.cancelledOrderCount, 1);
      await expectLater(
        harness.receivePayment(
          ReceivePaymentRequest(
            orderId: unpaid.orderId,
            cashierUserId: 'user_kasir',
            cashierName: 'kasir',
            amountPaid: item.subtotal,
          ),
        ),
        throwsStateError,
      );
    },
    skip: !FeatureFlags.payLater ? 'Requires FEATURE_PAY_LATER=true.' : false,
  );

  test('cash report excludes customer change from cash received', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final item = await harness.seedCartItem();

    await harness.checkout(
      CheckoutRequest(
        cashierUserId: 'user_kasir',
        cashierName: 'kasir',
        items: [item],
        orderType: OrderType.takeAway,
        customerName: 'Pelanggan',
        payNow: true,
        amountPaid: item.subtotal + 100000,
      ),
    );

    final report = await harness.todayReport();
    final payment = await harness.database
        .select(harness.database.payments)
        .getSingle();
    expect(payment.paymentMethod, PaymentMethod.cash.name);
    expect(report.totalCashReceived, item.subtotal);
    expect(report.totalRevenue, item.subtotal);
  });

  test(
    'transaction reset restores stock and preserves manual stock history',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final item = await harness.seedCartItem();
      await harness.catalog.adjustInventory(
        productId: item.productId,
        quantityAfter: 77,
        type: 'restock',
        notes: 'Restock sebelum penjualan',
      );
      await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.takeAway,
          customerName: 'Pelanggan',
          payNow: true,
          amountPaid: item.subtotal,
        ),
      );
      await harness.database
          .into(harness.database.pettyCash)
          .insert(
            PettyCashCompanion.insert(
              id: 'petty_test',
              amount: 5000,
              notes: 'Belanja kecil',
              cashierUserId: 'user_kasir',
              cashierName: 'kasir',
              createdAt: DateTime.now(),
            ),
          );
      await harness.settings.saveSetting('shift_active', 'true');

      final reset = ResetRepository(
        ResetDao(harness.database),
        SeedData(harness.database),
      );
      await reset.resetSelected(
        transactionalData: true,
        sessionLogs: false,
        referenceData: false,
        customers: false,
      );

      final snapshot = await harness.catalog.snapshot(activeOnly: false);
      final movements = await harness.catalog.stockMovementsForProduct(
        item.productId,
      );
      expect(snapshot.inventoryByProductId[item.productId]!.quantity, 77);
      expect(
        await harness.database.select(harness.database.orders).get(),
        isEmpty,
      );
      expect(
        await harness.database.select(harness.database.payments).get(),
        isEmpty,
      );
      expect(
        await harness.database.select(harness.database.pettyCash).get(),
        isEmpty,
      );
      expect(movements.map((row) => row.type), contains('restock'));
      expect(movements.map((row) => row.type), isNot(contains('sale')));
      final shiftSetting = await (harness.database.select(
        harness.database.settings,
      )..where((row) => row.key.equals('shift_active'))).getSingleOrNull();
      expect(shiftSetting, isNull);
    },
  );

  test('reference reset atomically restores bundled offline catalog', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final snapshot = await harness.catalog.snapshot(activeOnly: false);
    final category = snapshot.categories.firstWhere(
      (row) => row.parentId != null,
    );
    await harness.catalog.saveProduct(
      name: 'Produk Sementara',
      categoryId: category.id,
      basePrice: 12345,
      initialStock: 3,
    );
    final reset = ResetRepository(
      ResetDao(harness.database),
      SeedData(harness.database),
    );

    await reset.resetSelected(
      transactionalData: false,
      sessionLogs: false,
      referenceData: true,
      customers: false,
    );

    final restored = await harness.catalog.snapshot(activeOnly: false);
    expect(
      restored.products.any((row) => row.name == 'Produk Sementara'),
      isFalse,
    );
    expect(
      restored.products.any((row) => row.id == 'prod_talaga_aren'),
      isTrue,
    );
    expect(restored.inventoryByProductId['prod_talaga_aren']?.quantity, 50);
  });

  test(
    'reference reset refuses to orphan an active order',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final item = await harness.seedCartItem();
      await harness.checkout(
        CheckoutRequest(
          cashierUserId: 'user_kasir',
          cashierName: 'kasir',
          items: [item],
          orderType: OrderType.takeAway,
          customerName: 'Pelanggan',
          payNow: false,
        ),
      );
      final reset = ResetRepository(
        ResetDao(harness.database),
        SeedData(harness.database),
      );

      await expectLater(
        reset.resetSelected(
          transactionalData: false,
          sessionLogs: false,
          referenceData: true,
          customers: false,
        ),
        throwsStateError,
      );

      expect(
        await harness.database.select(harness.database.orders).get(),
        hasLength(1),
      );
      final snapshot = await harness.catalog.snapshot(activeOnly: false);
      expect(snapshot.products.any((row) => row.id == item.productId), isTrue);
    },
    skip: !FeatureFlags.payLater ? 'Requires FEATURE_PAY_LATER=true.' : false,
  );

  test('last active admin cannot be deleted or demoted', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    final usersDao = UsersDao(harness.database);
    final users = UserRepository(usersDao);
    final admin = (await usersDao.findById('user_admin'))!;

    await expectLater(
      users.deleteUser(admin.id, actorUserId: 'admin_lain'),
      throwsStateError,
    );
    await expectLater(
      users.updateUser(
        user: admin,
        username: admin.username,
        role: UserRole.cashier,
        actorUserId: 'admin_lain',
      ),
      throwsStateError,
    );
    await expectLater(
      users.deleteUser(admin.id, actorUserId: admin.id),
      throwsStateError,
    );
    await expectLater(
      users.setActive(admin, false, actorUserId: admin.id),
      throwsStateError,
    );
  });

  test(
    'active shift owner cannot be deleted, disabled, or change role',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.close);
      final usersDao = UsersDao(harness.database);
      final users = UserRepository(usersDao);
      final cashier = (await usersDao.findById('user_kasir'))!;
      final settings = SettingsDao(harness.database);
      await settings.openShift(
        cashierId: cashier.id,
        cashierName: cashier.cashierName,
        startTime: DateTime.now(),
        openingCash: 100000,
      );

      await expectLater(
        users.deleteUser(cashier.id, actorUserId: 'user_admin'),
        throwsStateError,
      );
      await expectLater(
        users.setActive(cashier, false, actorUserId: 'user_admin'),
        throwsStateError,
      );
      await expectLater(
        users.updateUser(
          user: cashier,
          username: cashier.username,
          role: UserRole.admin,
          actorUserId: 'user_admin',
        ),
        throwsStateError,
      );
    },
  );

  test('catalog CRUD rejects invalid data and cleans product joins', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.close);
    await expectLater(
      harness.catalog.saveAddon(name: ' ', price: 1000),
      throwsStateError,
    );
    await expectLater(
      harness.catalog.saveBean(name: 'Bean', hotPrice: -1, icePrice: 1000),
      throwsStateError,
    );
    await expectLater(harness.catalog.saveMethod(name: ' '), throwsStateError);

    const productId = 'prod_crud_cleanup';
    await harness.catalog.saveProduct(
      id: productId,
      name: 'Produk Hapus Bersih',
      categoryId: 'cat_coffee',
      basePrice: 10000,
      initialStock: 0,
    );
    final snapshot = await harness.catalog.snapshot(activeOnly: false);
    final product = snapshot.products.firstWhere((row) => row.id == productId);
    await harness.catalog.updateProductAddons(product.id, [
      snapshot.addons.first.id,
    ]);
    await harness.catalog.setProductFavorite(
      userId: 'user_admin',
      productId: product.id,
      isFavorite: true,
    );
    await harness.catalog.deleteProduct(product.id);
    final after = await harness.catalog.snapshot(activeOnly: false);
    expect(
      after.productAddons.where((row) => row.productId == product.id),
      isEmpty,
    );
    expect(after.inventoryByProductId[product.id], isNull);
    expect(
      await harness.catalog.watchFavoriteProductIds('user_admin').first,
      isEmpty,
    );
    await expectLater(
      harness.catalog.deleteCategory('cat_coffee'),
      throwsStateError,
    );
  });

  test(
    'disconnected printer blocks test print and cash drawer command',
    () async {
      final printer = FakePrinterService()
        ..statusValue = PrinterConnectionStatus.disconnected;
      final cashDrawer = CashDrawerService(printer);

      expect(await printer.testPrint(PaperSizeSetting.mm58), isFalse);
      expect(cashDrawer.readiness, CashDrawerCommandStatus.notReady);
      expect(await cashDrawer.testOpen(), CashDrawerCommandStatus.notReady);
    },
  );

  test('denied Bluetooth permission blocks native printer calls', () async {
    final printer = AndroidBluetoothPrinterService(
      permissionService: FakeBluetoothPermissionService(
        BluetoothPermissionState.denied,
      ),
    );

    expect(await printer.pairedDevices(), isEmpty);
    expect(
      await printer.connect(
        const PrinterDevice(name: 'Test Printer', address: '00:11'),
      ),
      isFalse,
    );
    expect(printer.status, PrinterConnectionStatus.error);
  });
}

class TestHarness {
  TestHarness._({
    required this.database,
    required this.auth,
    required this.catalog,
    required this.audit,
    required this.orders,
    required this.reports,
    required this.checkout,
    required this.receivePayment,
    required this.printer,
    required this.settings,
  });

  final AppDatabase database;
  final AuthRepository auth;
  final CatalogRepository catalog;
  final AuditRepository audit;
  final OrdersRepository orders;
  final ReportsRepository reports;
  final CheckoutUseCase checkout;
  final ReceivePaymentUseCase receivePayment;
  final FakePrinterService printer;
  final SettingsRepository settings;

  static Future<TestHarness> create() async {
    final database = AppDatabase(NativeDatabase.memory());
    await SeedData(database).ensureSeeded();
    final usersDao = UsersDao(database);
    final auditDao = AuditDao(database);
    final catalogDao = CatalogDao(database);
    final ordersDao = OrdersDao(database);
    final settingsDao = SettingsDao(database);
    final reportsDao = ReportsDao(database);
    final printerLogDao = PrinterLogDao(database);
    final settings = SettingsRepository(settingsDao);
    final orders = OrdersRepository(ordersDao, usersDao);
    final printer = FakePrinterService();
    final audit = AuditRepository(auditDao);
    return TestHarness._(
      database: database,
      auth: AuthRepository(usersDao),
      catalog: CatalogRepository(catalogDao, auditRepository: audit),
      audit: audit,
      orders: orders,
      reports: ReportsRepository(reportsDao),
      checkout: CheckoutUseCase(
        checkoutRepository: CheckoutRepository(
          ordersDao: ordersDao,
          catalogDao: catalogDao,
        ),
        ordersRepository: orders,
        printerLogRepository: PrinterLogRepository(printerLogDao),
        settingsRepository: settings,
        printerService: printer,
      ),
      receivePayment: ReceivePaymentUseCase(
        checkoutRepository: CheckoutRepository(
          ordersDao: ordersDao,
          catalogDao: catalogDao,
        ),
        ordersRepository: orders,
        settingsRepository: settings,
        printerService: printer,
      ),
      printer: printer,
      settings: settings,
    );
  }

  Future<CartItem> seedCartItem() async {
    final snapshot = await catalog.snapshot();
    final product = snapshot.products.firstWhere(
      (row) => row.id == 'prod_talaga_aren',
    );
    final category = snapshot.categoryById[product.categoryId]!;
    return CartItem(
      productId: product.id,
      productName: product.name,
      categoryName: category.name,
      unitPrice: product.hotPrice ?? product.basePrice,
      quantity: 1,
      temperatureOption: 'Hot',
      sugarOption: 'Normal Sugar',
      trackInventory: product.trackInventory,
    );
  }

  Future<dynamic> todayReport() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return reports.summary(start, end);
  }

  Future<void> close() => database.close();
}

class FakePrinterService implements PrinterService {
  final _controller = StreamController<PrinterConnectionStatus>.broadcast();
  PrinterConnectionStatus statusValue = PrinterConnectionStatus.disconnected;
  int printReceiptCalls = 0;
  int openCashDrawerCalls = 0;
  bool? cashDrawerResult;
  ReceiptData? lastReceipt;

  @override
  PrinterConnectionStatus get status => statusValue;

  @override
  Stream<PrinterConnectionStatus> get statusStream => _controller.stream;

  @override
  Future<bool> connect(PrinterDevice device) async {
    statusValue = PrinterConnectionStatus.connected;
    _controller.add(statusValue);
    return true;
  }

  @override
  Future<void> disconnect() async {
    statusValue = PrinterConnectionStatus.disconnected;
    _controller.add(statusValue);
  }

  @override
  Future<bool> openCashDrawer() async {
    openCashDrawerCalls++;
    return cashDrawerResult ?? status == PrinterConnectionStatus.connected;
  }

  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    return const [PrinterDevice(name: 'Test Printer', address: '00:11')];
  }

  @override
  Future<bool> printReceipt(
    ReceiptData data,
    PaperSizeSetting paperSize,
  ) async {
    printReceiptCalls++;
    lastReceipt = data;
    return status == PrinterConnectionStatus.connected;
  }

  @override
  Future<bool> testPrint(PaperSizeSetting paperSize) async {
    return status == PrinterConnectionStatus.connected;
  }
}

class FakeBluetoothPermissionService implements BluetoothPermissionService {
  FakeBluetoothPermissionService(this.state);

  BluetoothPermissionState state;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<BluetoothPermissionState> request() async => state;

  @override
  Future<BluetoothPermissionState> status() async => state;
}

class FakeReportFileSaver implements ReportFileSaver {
  String? savedFileName;
  Uint8List? savedBytes;

  @override
  Future<String> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    savedFileName = fileName;
    savedBytes = bytes;
    return 'content://downloads/$fileName';
  }
}
