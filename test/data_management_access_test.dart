import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/domain/models/enums.dart';
import 'package:talaga_coffee_pos/presentation/settings/widgets/data_management_section.dart';

void main() {
  testWidgets('cashier cannot access destructive outlet reset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DataManagementSection(role: UserRole.cashier)),
      ),
    );

    expect(find.text('Data Operasional Terlindungi'), findsOneWidget);
    expect(find.text('Bersihkan Data Transaksi'), findsNothing);
    expect(find.text('Buka Panel Reset Data'), findsNothing);
  });

  testWidgets('admin retains the guarded reset entry point', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DataManagementSection(role: UserRole.admin)),
        ),
      ),
    );

    expect(find.text('Buka Panel Reset Data'), findsOneWidget);
    expect(find.text('Bersihkan Data Transaksi'), findsNothing);

    await tester.tap(find.text('Buka Panel Reset Data'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Log Aktivitas & Printer'), findsOneWidget);
    expect(find.text('Katalog & Persediaan Bawaan'), findsOneWidget);
    expect(find.text('Data Pelanggan'), findsNothing);
    expect(find.text('Keranjang Aktif'), findsNothing);
  });
}
