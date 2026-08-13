import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/core/config/feature_flags.dart';
import 'package:talaga_coffee_pos/core/routing/app_destination.dart';
import 'package:talaga_coffee_pos/data/database/app_database.dart';
import 'package:talaga_coffee_pos/domain/models/enums.dart';
import 'package:talaga_coffee_pos/presentation/dashboard/dashboard_shell.dart';
import 'package:talaga_coffee_pos/presentation/providers/app_providers.dart';

void main() {
  test('feature flags dapat dibaca pada saat kompilasi', () {
    expect(FeatureFlags.customerNameShortcut, isA<bool>());
    expect(FeatureFlags.tableNumber, isA<bool>());
    expect(FeatureFlags.payLater, isA<bool>());
    expect(FeatureFlags.ordersQueue, isA<bool>());
    expect(FeatureFlags.adminPosAccess, isA<bool>());
    expect(FeatureFlags.cancelledOrdersReport, isA<bool>());
    expect(FeatureFlags.inventoryManagementSetting, isA<bool>());
  });

  test(
    'akses POS kasir tetap aktif dan akses admin mengikuti feature flag',
    () {
      expect(AppDestination.pos.isAllowed(UserRole.cashier), isTrue);
      expect(
        AppDestination.pos.isAllowed(UserRole.admin),
        FeatureFlags.adminPosAccess,
      );
      expect(
        AppDestination.forRole(UserRole.admin).contains(AppDestination.pos),
        FeatureFlags.adminPosAccess,
      );
    },
  );

  test('akses antrean pesanan mengikuti feature flag untuk semua role', () {
    expect(
      AppDestination.orders.isAllowed(UserRole.cashier),
      FeatureFlags.ordersQueue,
    );
    expect(
      AppDestination.orders.isAllowed(UserRole.admin),
      FeatureFlags.ordersQueue,
    );
    expect(
      AppDestination.forRole(UserRole.cashier).contains(AppDestination.orders),
      FeatureFlags.ordersQueue,
    );
    expect(
      AppDestination.forRole(UserRole.admin).contains(AppDestination.orders),
      FeatureFlags.ordersQueue,
    );
  });

  testWidgets(
    'shell kasir compact aman ketika tujuan navigasi kurang dari dua',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime(2026, 7, 17);
      final user = UserRecord(
        id: 'cashier-test',
        username: 'kasir-test',
        displayName: 'Kasir Test',
        passwordHash: 'unused',
        role: UserRole.cashier.name,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(home: DashboardShell(user: user)),
        ),
      );
      await tester.pump();

      final cashierDestinations = AppDestination.forRole(
        UserRole.cashier,
      ).where((destination) => destination != AppDestination.settings);
      expect(tester.takeException(), isNull);
      expect(
        find.byType(NavigationBar),
        cashierDestinations.length >= 2 ? findsOneWidget : findsNothing,
      );
    },
  );
}
