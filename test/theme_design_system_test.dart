import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/theme/app_colors.dart';
import 'package:talaga_coffee_pos/theme/app_layout.dart';
import 'package:talaga_coffee_pos/theme/app_role_tokens.dart';
import 'package:talaga_coffee_pos/theme/app_semantic_colors.dart';
import 'package:talaga_coffee_pos/theme/app_theme.dart';
import 'package:talaga_coffee_pos/theme/app_typography.dart';
import 'package:talaga_coffee_pos/widgets/common/app_page_header.dart';
import 'package:talaga_coffee_pos/widgets/common/app_state_view.dart';

void main() {
  test('theme visual berbeda untuk guest, kasir, dan admin', () {
    expect(
      AppTheme.guest(false).extension<AppRoleTokens>()?.role,
      AppVisualRole.guest,
    );
    expect(
      AppTheme.cashier(false).extension<AppRoleTokens>()?.role,
      AppVisualRole.cashier,
    );
    expect(
      AppTheme.admin(false).extension<AppRoleTokens>()?.role,
      AppVisualRole.admin,
    );

    expect(AppTheme.guest(false).colorScheme.primary, AppColors.wood700);
    expect(AppTheme.cashier(false).colorScheme.primary, AppColors.lake700);
    expect(AppTheme.admin(false).colorScheme.primary, AppColors.wood700);
    expect(
      AppTheme.cashier(false).extension<AppRoleTokens>()!.primaryControlHeight,
      greaterThan(
        AppTheme.admin(false).extension<AppRoleTokens>()!.primaryControlHeight,
      ),
    );
    expect(
      AppTheme.admin(false).extension<AppRoleTokens>()!.minTapTarget,
      AppLayout.adminPrimaryControlHeight,
    );
    expect(
      AppTheme.admin(false).extension<AppSemanticColors>(),
      same(AppSemanticColors.light),
    );
    expect(
      AppTheme.cashier(true).extension<AppSemanticColors>(),
      same(AppSemanticColors.dark),
    );
  });

  test('palet chart berasal dari keluarga warna kayu dan danau', () {
    expect(AppColors.chartPalette, hasLength(10));
    expect(AppColors.chartColorAt(0), AppColors.lake700);
    expect(AppColors.chartColorAt(1), AppColors.wood700);
    expect(AppColors.chartColorAt(12), isNot(AppColors.chartPalette[2]));
    expect(AppColors.darkChartPalette, hasLength(10));
    expect(AppColors.darkChartColorAt(0), AppColors.lake300);
    expect(AppColors.darkChartColorAt(1), AppColors.clay300);
  });

  test('system bars mengikuti surface Android dan masthead role', () {
    final cashierLight = AppTheme.cashier(false);
    final adminDark = AppTheme.admin(true);

    expect(
      cashierLight.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
    expect(
      cashierLight.appBarTheme.systemOverlayStyle?.systemNavigationBarColor,
      cashierLight.colorScheme.surface,
    );
    expect(
      adminDark.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
    expect(
      adminDark.appBarTheme.systemOverlayStyle?.systemNavigationBarColor,
      adminDark.colorScheme.surface,
    );
  });

  test('tipografi memilih skala compact dan expanded dari available width', () {
    final compact = AppTypography.textThemeForWidth(599);
    final medium = AppTypography.textThemeForWidth(600);
    final expanded = AppTypography.textThemeForWidth(840);

    expect(compact.displayLarge!.fontSize, 28);
    expect(compact.headlineMedium!.fontSize, 24);
    expect(compact.titleLarge!.fontSize, 20);
    expect(medium.displayLarge!.fontSize, 32);
    expect(medium.headlineMedium!.fontSize, 28);
    expect(expanded.titleLarge!.fontSize, 22);
  });

  test('AppTheme.responsive mempertahankan role dan warna semantic', () {
    final base = AppTheme.cashier(true);
    final compact = AppTheme.responsive(base, 599);
    final expanded = AppTheme.responsive(base, 840);

    expect(compact.textTheme.headlineMedium!.fontSize, 24);
    expect(expanded.textTheme.headlineMedium!.fontSize, 28);
    expect(compact.textTheme.bodyMedium!.color, base.colorScheme.onSurface);
    expect(
      compact.primaryTextTheme.bodyMedium!.color,
      base.appBarTheme.foregroundColor,
    );
    expect(
      compact.appBarTheme.titleTextStyle!.color,
      base.appBarTheme.foregroundColor,
    );
    expect(compact.extension<AppRoleTokens>()!.role, AppVisualRole.cashier);
    expect(
      compact.extension<AppSemanticColors>(),
      same(AppSemanticColors.dark),
    );
  });

  testWidgets('header admin tidak overflow pada layar compact', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.admin(false),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AppPageHeader(
              eyebrow: 'OPERASIONAL',
              title: 'Judul halaman admin yang cukup panjang',
              description: 'Deskripsi tetap dapat dibaca pada layar kecil.',
              action: FilledButton(onPressed: null, child: Text('Aksi utama')),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Aksi utama'), findsOneWidget);
    final title = tester.widget<Text>(
      find.text('Judul halaman admin yang cukup panjang'),
    );
    expect(title.style!.fontSize, 24);
  });

  testWidgets('header memakai skala expanded tepat pada lebar 840', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(840, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.admin(false),
        home: const Scaffold(body: AppPageHeader(title: 'Ringkasan outlet')),
      ),
    );

    final title = tester.widget<Text>(find.text('Ringkasan outlet'));
    expect(title.style!.fontSize, 28);
    expect(tester.takeException(), isNull);
  });

  testWidgets('state error dan empty memakai pesan Bahasa Indonesia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cashier(false),
        home: const Scaffold(
          body: Column(
            children: [
              Expanded(child: AppErrorState()),
              Expanded(child: AppEmptyState(title: 'Belum ada pesanan')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Data belum dapat dimuat'), findsOneWidget);
    expect(find.text('Belum ada pesanan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
