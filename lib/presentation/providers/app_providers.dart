import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/printer/android_bluetooth_printer_service.dart';
import '../../core/files/report_file_saver.dart';
import '../../core/permissions/bluetooth_permission_service.dart';
import '../../core/printer/cash_drawer_service.dart';
import '../../core/printer/printer_service.dart';
import '../../core/routing/app_destination.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/catalog_dao.dart';
import '../../data/database/daos/orders_dao.dart';
import '../../data/database/daos/audit_dao.dart';
import '../../data/database/daos/printer_log_dao.dart';
import '../../data/database/daos/reports_dao.dart';
import '../../data/database/daos/settings_dao.dart';
import '../../data/database/daos/users_dao.dart';
import '../../data/database/daos/reset_dao.dart';
import '../../data/database/seed_data.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/printer_log_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/reset_repository.dart';
import '../../domain/models/cart_models.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/report_models.dart';
import '../../domain/models/session_models.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/usecases/report_export_usecase.dart';
import '../../domain/usecases/receipt_usecase.dart';
import '../../domain/usecases/receive_payment_usecase.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../domain/repositories/checkout_repository_contract.dart';
import '../../core/utils/id_generator.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final seedProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(databaseProvider);
  await SeedData(database).ensureSeeded();
});

final usersDaoProvider = Provider<UsersDao>((ref) {
  return UsersDao(ref.watch(databaseProvider));
});

final catalogDaoProvider = Provider<CatalogDao>((ref) {
  return CatalogDao(ref.watch(databaseProvider));
});

final auditDaoProvider = Provider<AuditDao>((ref) {
  return AuditDao(ref.watch(databaseProvider));
});

final printerLogDaoProvider = Provider<PrinterLogDao>((ref) {
  return PrinterLogDao(ref.watch(databaseProvider));
});

final ordersDaoProvider = Provider<OrdersDao>((ref) {
  return OrdersDao(ref.watch(databaseProvider));
});

final reportsDaoProvider = Provider<ReportsDao>((ref) {
  return ReportsDao(ref.watch(databaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(databaseProvider));
});

final resetDaoProvider = Provider<ResetDao>((ref) {
  return ResetDao(ref.watch(databaseProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(usersDaoProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(usersDaoProvider));
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(auditDaoProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(
    ref.watch(catalogDaoProvider),
    auditRepository: ref.watch(auditRepositoryProvider),
  );
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(
    ref.watch(ordersDaoProvider),
    ref.watch(usersDaoProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(settingsDaoProvider));
});

final resetRepositoryProvider = Provider<ResetRepository>((ref) {
  return ResetRepository(
    ref.watch(resetDaoProvider),
    SeedData(ref.watch(databaseProvider)),
  );
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(reportsDaoProvider));
});

final printerLogRepositoryProvider = Provider<PrinterLogRepository>((ref) {
  return PrinterLogRepository(ref.watch(printerLogDaoProvider));
});

final bluetoothPermissionServiceProvider = Provider<BluetoothPermissionService>(
  (ref) {
    return AndroidBluetoothPermissionService();
  },
);

final printerServiceProvider = Provider<PrinterService>((ref) {
  return AndroidBluetoothPrinterService(
    permissionService: ref.watch(bluetoothPermissionServiceProvider),
  );
});

final cashDrawerServiceProvider = Provider<CashDrawerService>((ref) {
  return CashDrawerService(ref.watch(printerServiceProvider));
});

final checkoutRepositoryProvider = Provider<CheckoutRepositoryContract>((ref) {
  return CheckoutRepository(
    ordersDao: ref.watch(ordersDaoProvider),
    catalogDao: ref.watch(catalogDaoProvider),
  );
});

final checkoutUseCaseProvider = Provider<CheckoutUseCase>((ref) {
  return CheckoutUseCase(
    checkoutRepository: ref.watch(checkoutRepositoryProvider),
    ordersRepository: ref.watch(ordersRepositoryProvider),
    printerLogRepository: ref.watch(printerLogRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    printerService: ref.watch(printerServiceProvider),
  );
});

final receivePaymentUseCaseProvider = Provider<ReceivePaymentUseCase>((ref) {
  return ReceivePaymentUseCase(
    checkoutRepository: ref.watch(checkoutRepositoryProvider),
    ordersRepository: ref.watch(ordersRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    printerService: ref.watch(printerServiceProvider),
  );
});

final receiptUseCaseProvider = Provider<ReceiptUseCase>((ref) {
  return ReceiptUseCase(
    ordersRepository: ref.watch(ordersRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    printerService: ref.watch(printerServiceProvider),
  );
});

final reportExportUseCaseProvider = Provider<ReportExportUseCase>((ref) {
  return ReportExportUseCase(
    reportsRepository: ref.watch(reportsRepositoryProvider),
    fileSaver: AndroidDownloadsReportFileSaver(),
    auditRepository: ref.watch(auditRepositoryProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, SessionState>(AuthController.new);

class AuthController extends AsyncNotifier<SessionState> {
  @override
  FutureOr<SessionState> build() async {
    await ref.watch(seedProvider.future);
    return const SessionState();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username, password);
      ref
          .read(selectedDestinationProvider.notifier)
          .select(AppDestination.initialForRole(UserRole.fromDb(user.role)));
      return SessionState(user: user);
    });
  }

  void logout() {
    ref.read(cartControllerProvider.notifier).clear();
    ref.read(selectedDestinationProvider.notifier).select(AppDestination.pos);
    state = const AsyncData(SessionState());
  }

  Future<void> updateCashierName(String displayName) async {
    final user = state.value?.user;
    if (user == null || UserRole.fromDb(user.role) != UserRole.cashier) {
      throw StateError('Sesi kasir tidak tersedia');
    }
    final updatedUser = await ref
        .read(userRepositoryProvider)
        .updateDisplayName(user, displayName);
    state = AsyncData(SessionState(user: updatedUser));
  }
}

final selectedDestinationProvider =
    NotifierProvider<SelectedDestinationController, AppDestination>(
      SelectedDestinationController.new,
    );

class SelectedDestinationController extends Notifier<AppDestination> {
  @override
  AppDestination build() => AppDestination.pos;

  void select(AppDestination destination) {
    state = destination;
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void add(CartItem item) {
    bool isSameAddons(List<CartAddon> a, List<CartAddon> b) {
      if (a.length != b.length) return false;
      final setA = a.map((e) => e.id).toSet();
      final setB = b.map((e) => e.id).toSet();
      return setA.difference(setB).isEmpty;
    }

    final existingIndex = state.items.indexWhere(
      (existing) =>
          existing.productId == item.productId &&
          existing.temperatureOption == item.temperatureOption &&
          existing.sugarOption == item.sugarOption &&
          existing.manualBrewMethodId == item.manualBrewMethodId &&
          existing.beanId == item.beanId &&
          existing.notes == item.notes &&
          isSameAddons(existing.addons, item.addons),
    );

    if (existingIndex != -1) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      state = state.copyWith(
        items: [
          for (int i = 0; i < state.items.length; i++)
            if (i == existingIndex) updatedItem else state.items[i],
        ],
      );
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateQuantity(String lineId, int quantity) {
    if (quantity < 1) {
      return;
    }
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.lineId == lineId)
            item.copyWith(quantity: quantity)
          else
            item,
      ],
    );
  }

  void updateTemperatureOption(
    String lineId,
    String temperatureOption, {
    int? unitPrice,
  }) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.lineId == lineId)
            item.copyWith(
              temperatureOption: temperatureOption,
              unitPrice: unitPrice ?? item.unitPrice,
            )
          else
            item,
      ],
    );
  }

  void updateSugarOption(String lineId, String sugarOption) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.lineId == lineId)
            item.copyWith(sugarOption: sugarOption)
          else
            item,
      ],
    );
  }

  void updateNotes(String lineId, String notes) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.lineId == lineId)
            item.copyWith(notes: notes.trim().isEmpty ? null : notes)
          else
            item,
      ],
    );
  }

  void remove(String lineId) {
    state = state.copyWith(
      items: state.items.where((item) => item.lineId != lineId).toList(),
    );
  }

  void clear() {
    state = const CartState();
  }
}

final catalogSnapshotProvider = FutureProvider<CatalogSnapshot>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.watch(catalogRepositoryProvider).snapshot();
});

final favoriteProductIdsProvider = StreamProvider<Set<String>>((ref) async* {
  await ref.watch(seedProvider.future);
  final user = ref.watch(authControllerProvider).value?.user;
  if (user == null) {
    yield const <String>{};
    return;
  }
  yield* ref.watch(catalogRepositoryProvider).watchFavoriteProductIds(user.id);
});

final adminCatalogSnapshotProvider = FutureProvider<CatalogSnapshot>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  return ref.watch(catalogRepositoryProvider).snapshot(activeOnly: false);
});

final ordersProvider = StreamProvider<List<OrderRecord>>((ref) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(ordersRepositoryProvider).watchOrders();
});

final usersProvider = StreamProvider<List<UserRecord>>((ref) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(userRepositoryProvider).watchUsers();
});

final settingsProvider = FutureProvider<Map<String, String>>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.watch(settingsRepositoryProvider).allSettings();
});

final printerSettingsProvider = FutureProvider<PrinterSettingRecord>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  return ref.watch(settingsRepositoryProvider).printerSettings();
});

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  await ref.watch(seedProvider.future);
  ref.watch(ordersProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(reportsRepositoryProvider).summary(start, end);
});

final reportSummaryForRangeProvider =
    FutureProvider.family<ReportSummary, ReportRange>((ref, range) async {
      await ref.watch(seedProvider.future);
      ref.watch(ordersProvider);
      return ref
          .watch(reportsRepositoryProvider)
          .summary(range.start, range.end);
    });

final dashboardAnalyticsProvider =
    FutureProvider.family<DashboardAnalytics, ReportRange>((ref, range) async {
      await ref.watch(seedProvider.future);
      ref.watch(ordersProvider);
      final repository = ref.watch(reportsRepositoryProvider);
      final now = DateTime.now();
      final today = ReportRange.today(now);
      final yesterday = ReportRange.yesterday(now);
      final buckets = _dashboardBuckets(range);

      final results = await Future.wait([
        repository.summary(range.start, range.end),
        repository.summary(today.start, today.end),
        repository.summary(yesterday.start, yesterday.end),
        ...buckets.map(
          (bucket) => repository.summary(bucket.start, bucket.end),
        ),
      ]);

      return DashboardAnalytics(
        range: range,
        rangeSummary: results[0],
        todaySummary: results[1],
        yesterdaySummary: results[2],
        chartPoints: [
          for (var index = 0; index < buckets.length; index++)
            ReportChartPoint(
              start: buckets[index].start,
              end: buckets[index].end,
              label: buckets[index].label,
              summary: results[index + 3],
            ),
        ],
      );
    });

final revenueComparisonProvider =
    FutureProvider.family<RevenueComparison, RevenueComparisonPeriod>((
      ref,
      period,
    ) async {
      await ref.watch(seedProvider.future);
      ref.watch(ordersProvider);
      final repository = ref.watch(reportsRepositoryProvider);
      final now = DateTime.now();
      final currentEnd = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      final currentStart = currentEnd.subtract(Duration(days: period.days));
      final previousEnd = currentStart;
      final previousStart = previousEnd.subtract(Duration(days: period.days));
      final currentRange = ReportRange(
        start: currentStart,
        end: currentEnd,
        label: '${period.days} hari terakhir',
      );
      final previousRange = ReportRange(
        start: previousStart,
        end: previousEnd,
        label: '${period.days} hari sebelumnya',
      );
      final summaries = await Future.wait([
        repository.summary(currentRange.start, currentRange.end),
        repository.summary(previousRange.start, previousRange.end),
      ]);
      return RevenueComparison(
        period: period,
        currentRange: currentRange,
        previousRange: previousRange,
        currentSummary: summaries[0],
        previousSummary: summaries[1],
      );
    });

List<ReportRange> _dashboardBuckets(ReportRange range) {
  final totalDays = range.end.difference(range.start).inDays;
  if (totalDays <= 1) {
    return List.generate(6, (index) {
      final start = range.start.add(Duration(hours: index * 4));
      final end = start.add(const Duration(hours: 4));
      return ReportRange(
        start: start,
        end: end.isAfter(range.end) ? range.end : end,
        label: '${start.hour.toString().padLeft(2, '0')}:00',
      );
    });
  }

  final bucketDays = totalDays <= 14 ? 1 : (totalDays / 14).ceil();
  final buckets = <ReportRange>[];
  var start = range.start;
  while (start.isBefore(range.end)) {
    final candidateEnd = start.add(Duration(days: bucketDays));
    final end = candidateEnd.isAfter(range.end) ? range.end : candidateEnd;
    buckets.add(ReportRange(start: start, end: end, label: 'Grafik'));
    start = end;
  }
  return buckets;
}

final auditLogsProvider = FutureProvider<List<AuditLogRecord>>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.watch(auditRepositoryProvider).recent();
});

final printerLogsProvider = FutureProvider<List<PrinterLogRecord>>((ref) async {
  await ref.watch(seedProvider.future);
  return ref.watch(printerLogRepositoryProvider).recent();
});

final printerStatusProvider = StreamProvider<PrinterConnectionStatus>((
  ref,
) async* {
  final service = ref.watch(printerServiceProvider);
  yield service.status;
  yield* service.statusStream;
});

class ShiftState {
  const ShiftState({
    this.isActive = false,
    this.cashierId,
    this.cashierName,
    this.startTime,
    this.openingCash = 0,
  });

  final bool isActive;
  final String? cashierId;
  final String? cashierName;
  final DateTime? startTime;
  final int openingCash;

  ShiftState copyWith({
    bool? isActive,
    String? cashierId,
    String? cashierName,
    DateTime? startTime,
    int? openingCash,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      startTime: startTime ?? this.startTime,
      openingCash: openingCash ?? this.openingCash,
    );
  }
}

final shiftControllerProvider =
    AsyncNotifierProvider<ShiftController, ShiftState>(ShiftController.new);

class ShiftController extends AsyncNotifier<ShiftState> {
  @override
  FutureOr<ShiftState> build() async {
    final settings = ref.watch(settingsDaoProvider);
    final values = await settings.allSettings();
    if (values['shift_active'] == 'true') {
      final cashierId = values['shift_cashier_id'];
      final cashierName = values['shift_cashier_name'];
      final startTime = DateTime.tryParse(values['shift_start_time'] ?? '');
      final openingCash = int.tryParse(values['shift_opening_cash'] ?? '');
      if (cashierId == null ||
          cashierName == null ||
          startTime == null ||
          openingCash == null ||
          openingCash < 0) {
        // Pulihkan data lama/parsial agar semua kasir tidak terkunci permanen.
        await settings.closeShift();
        return const ShiftState();
      }
      return ShiftState(
        isActive: true,
        cashierId: cashierId,
        cashierName: cashierName,
        startTime: startTime,
        openingCash: openingCash,
      );
    }
    return const ShiftState();
  }

  Future<void> openShift({
    required String cashierId,
    required String cashierName,
    required int openingCash,
  }) async {
    final normalizedCashierName = cashierName.trim();
    if (normalizedCashierName.isEmpty) {
      throw StateError('Nama kasir wajib diisi');
    }
    if (openingCash < 0) {
      throw StateError('Modal awal tidak boleh negatif');
    }
    final settings = ref.read(settingsDaoProvider);
    final persistedActive = await settings.value('shift_active') == 'true';
    if (persistedActive) {
      final persistedCashierId = await settings.value('shift_cashier_id');
      final persistedCashierName = await settings.value('shift_cashier_name');
      if (persistedCashierId != cashierId) {
        throw StateError(
          'Shift ${persistedCashierName ?? 'kasir lain'} masih aktif. Ganti ke akun pemilik shift untuk menutupnya.',
        );
      }
      throw StateError('Shift kasir ini masih aktif dan tidak boleh ditimpa');
    }

    state = const AsyncLoading();
    try {
      final startedAt = DateTime.now();
      await settings.openShift(
        cashierId: cashierId,
        cashierName: normalizedCashierName,
        startTime: startedAt,
        openingCash: openingCash,
      );
      state = AsyncData(
        ShiftState(
          isActive: true,
          cashierId: cashierId,
          cashierName: normalizedCashierName,
          startTime: startedAt,
          openingCash: openingCash,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> closeShift() async {
    state = const AsyncLoading();
    try {
      final settings = ref.read(settingsDaoProvider);
      await settings.closeShift();
      state = const AsyncData(ShiftState());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final shiftCashSalesProvider = FutureProvider<int>((ref) async {
  final shift = ref.watch(shiftControllerProvider).value;
  if (shift == null || !shift.isActive || shift.startTime == null) {
    return 0;
  }
  ref.watch(ordersProvider);
  final database = ref.read(databaseProvider);
  final paymentQuery = database.select(database.payments)
    ..where((tbl) {
      var predicate =
          tbl.paymentMethod.isIn(PaymentMethod.cashDbValues) &
          tbl.paidAt.isBiggerOrEqualValue(shift.startTime!);
      final cashierId = shift.cashierId;
      if (cashierId != null) {
        predicate = predicate & tbl.cashierUserId.equals(cashierId);
      }
      return predicate;
    });
  final payments = await paymentQuery.get();
  if (payments.isEmpty) {
    return 0;
  }
  final orderIds = payments.map((payment) => payment.orderId).toSet();
  final validOrders =
      await (database.select(database.orders)..where(
            (tbl) =>
                tbl.id.isIn(orderIds.toList()) &
                tbl.paymentStatus.equals(PaymentStatus.paid.name) &
                tbl.orderStatus.isNotIn([OrderStatus.cancelled.name]),
          ))
          .get();
  final validOrderIds = validOrders.map((order) => order.id).toSet();
  return payments
      .where((payment) => validOrderIds.contains(payment.orderId))
      .fold<int>(0, (sum, row) => sum + row.amountPaid - row.changeAmount);
});

final shiftPettyCashEntriesProvider = FutureProvider<List<PettyCashRecord>>((
  ref,
) async {
  final shift = ref.watch(shiftControllerProvider).value;
  if (shift == null || !shift.isActive || shift.startTime == null) {
    return const [];
  }
  final database = ref.read(databaseProvider);
  return (database.select(database.pettyCash)
        ..where((tbl) {
          var predicate = tbl.createdAt.isBiggerOrEqualValue(shift.startTime!);
          final cashierId = shift.cashierId;
          if (cashierId != null) {
            predicate = predicate & tbl.cashierUserId.equals(cashierId);
          }
          return predicate;
        })
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
      .get();
});

final shiftPettyCashProvider = FutureProvider<int>((ref) async {
  final entries = await ref.watch(shiftPettyCashEntriesProvider.future);
  return entries.fold<int>(0, (sum, row) => sum + row.amount);
});

class PettyCashController extends AsyncNotifier<List<PettyCashRecord>> {
  @override
  FutureOr<List<PettyCashRecord>> build() async {
    final database = ref.read(databaseProvider);
    return database.select(database.pettyCash).get();
  }

  Future<void> addEntry({required int amount, required String notes}) async {
    final user = ref.read(authControllerProvider).value?.user;
    if (user == null) {
      throw StateError('Sesi kasir tidak tersedia');
    }
    if (UserRole.fromDb(user.role) != UserRole.cashier) {
      throw StateError('Kas keluar hanya dapat dicatat oleh kasir');
    }
    final shift = await ref.read(shiftControllerProvider.future);
    if (!shift.isActive || shift.cashierId != user.id) {
      throw StateError('Buka shift kasir ini sebelum mencatat kas keluar');
    }
    if (amount <= 0) {
      throw StateError('Jumlah kas keluar harus lebih besar dari 0');
    }
    final normalizedNotes = notes.trim();
    if (normalizedNotes.isEmpty) {
      throw StateError('Keterangan kas keluar wajib diisi');
    }

    final database = ref.read(databaseProvider);
    final entry = PettyCashRecord(
      id: IdGenerator.create(),
      amount: amount,
      notes: normalizedNotes,
      cashierUserId: user.id,
      cashierName: shift.cashierName ?? user.cashierName,
      createdAt: DateTime.now(),
    );
    await database.into(database.pettyCash).insert(entry);
    ref.invalidateSelf();
    ref.invalidate(shiftPettyCashEntriesProvider);
    ref.invalidate(shiftPettyCashProvider);
  }
}

final pettyCashControllerProvider =
    AsyncNotifierProvider<PettyCashController, List<PettyCashRecord>>(
      PettyCashController.new,
    );

class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settingsVal = ref.watch(settingsProvider).value;
    if (settingsVal == null) return false;
    return settingsVal['dark_mode_enabled'] == 'true';
  }

  Future<void> toggle() async {
    final nextValue = !state;
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting('dark_mode_enabled', nextValue ? 'true' : 'false');
    ref.invalidate(settingsProvider);
  }
}

final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);
