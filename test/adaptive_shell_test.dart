import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/core/routing/app_destination.dart';
import 'package:talaga_coffee_pos/data/database/app_database.dart';
import 'package:talaga_coffee_pos/domain/models/enums.dart';
import 'package:talaga_coffee_pos/presentation/auth/login_screen.dart';
import 'package:talaga_coffee_pos/presentation/dashboard/dashboard_shell.dart';
import 'package:talaga_coffee_pos/presentation/providers/app_providers.dart';

void main() {
  testWidgets('login aman saat viewport Android sementara sangat pendek', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await database.close();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(320, 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shell kasir berpindah rail, drawer, dan compact-height tanpa kehilangan tujuan',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
        await tester.binding.setSurfaceSize(null);
      });

      final now = DateTime(2026, 7, 18);
      final user = UserRecord(
        id: 'cashier-adaptive',
        username: 'kasir-adaptive',
        displayName: 'Kasir Adaptif',
        passwordHash: 'unused',
        role: UserRole.cashier.name,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await tester.binding.setSurfaceSize(const Size(700, 800));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: DashboardShell(user: user)),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Ruang Kasir'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();

      expect(find.text('Ruang Kasir'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      container
          .read(selectedDestinationProvider.notifier)
          .select(AppDestination.settings);
      await tester.binding.setSurfaceSize(const Size(900, 479));
      await tester.pump();

      expect(find.text('Pengaturan Kasir'), findsWidgets);
      expect(find.text('Ruang Kasir'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
