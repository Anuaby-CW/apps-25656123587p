import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/theme/app_colors.dart';
import 'package:talaga_coffee_pos/theme/app_semantic_colors.dart';
import 'package:talaga_coffee_pos/theme/app_theme.dart';
import 'package:talaga_coffee_pos/widgets/common/app_alert.dart';
import 'package:talaga_coffee_pos/widgets/common/app_dropdown_field.dart';
import 'package:talaga_coffee_pos/widgets/common/app_section_card.dart';
import 'package:talaga_coffee_pos/widgets/common/app_status_badge.dart';

const _noStates = <WidgetState>{};
const _selected = <WidgetState>{WidgetState.selected};

void main() {
  final darkThemes = <String, ThemeData>{
    'guest': AppTheme.guest(true),
    'cashier': AppTheme.cashier(true),
    'admin': AppTheme.admin(true),
  };

  test('dark ColorScheme memakai token DESIGN dan identitas role terbaru', () {
    for (final entry in darkThemes.entries) {
      final theme = entry.value;
      final scheme = theme.colorScheme;

      expect(theme.scaffoldBackgroundColor, AppColors.darkCanvas);
      expect(theme.canvasColor, AppColors.darkCanvas);
      expect(scheme.surface, AppColors.darkSurface);
      expect(scheme.surfaceDim, AppColors.darkSurfaceDim);
      expect(scheme.surfaceBright, AppColors.darkSurfaceBright);
      expect(scheme.surfaceContainerLowest, AppColors.darkContainerLowest);
      expect(scheme.surfaceContainerLow, AppColors.darkContainerLow);
      expect(scheme.surfaceContainer, AppColors.darkContainer);
      expect(scheme.surfaceContainerHigh, AppColors.darkContainerHigh);
      expect(scheme.surfaceContainerHighest, AppColors.darkContainerHighest);
      expect(scheme.onSurface, AppColors.darkOnSurface);
      expect(scheme.onSurfaceVariant, AppColors.darkOnSurfaceVariant);
      expect(scheme.outline, AppColors.darkOutline);
      expect(scheme.outlineVariant, AppColors.darkOutlineVariant);
      expect(scheme.inverseSurface, AppColors.darkInverseSurface);
      expect(scheme.onInverseSurface, AppColors.darkOnInverseSurface);
      expect(scheme.scrim, AppColors.darkScrim);
      expect(scheme.error, AppColors.darkError);
      expect(scheme.onError, AppColors.darkOnError);
      expect(scheme.errorContainer, AppColors.darkErrorContainer);
      expect(scheme.onErrorContainer, AppColors.darkOnErrorContainer);
      expect(
        theme.extension<AppSemanticColors>(),
        same(AppSemanticColors.dark),
      );
    }

    final guest = darkThemes['guest']!.colorScheme;
    final admin = darkThemes['admin']!.colorScheme;
    final cashier = darkThemes['cashier']!.colorScheme;

    for (final scheme in [guest, admin]) {
      expect(scheme.primary, AppColors.clay300);
      expect(scheme.onPrimary, AppColors.wood950);
      expect(scheme.primaryContainer, AppColors.wood800);
      expect(scheme.onPrimaryContainer, AppColors.cream100);
      expect(scheme.secondary, AppColors.lake400);
      expect(scheme.onSecondary, AppColors.lake950);
      expect(scheme.secondaryContainer, AppColors.lake800);
      expect(scheme.onSecondaryContainer, AppColors.lake100);
    }

    expect(cashier.primary, AppColors.lake300);
    expect(cashier.onPrimary, AppColors.lake950);
    expect(cashier.primaryContainer, AppColors.lake800);
    expect(cashier.onPrimaryContainer, AppColors.lake100);
    expect(cashier.secondary, AppColors.clay300);
    expect(cashier.onSecondary, AppColors.wood950);
    expect(cashier.secondaryContainer, AppColors.wood800);
    expect(cashier.onSecondaryContainer, AppColors.cream100);

    expect(darkThemes['admin']!.appBarTheme.backgroundColor, AppColors.wood800);
    expect(
      darkThemes['cashier']!.appBarTheme.backgroundColor,
      AppColors.lake800,
    );
  });

  test('dark component themes use semantic ColorScheme colors', () {
    for (final entry in darkThemes.entries) {
      final role = entry.key;
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final input = theme.inputDecorationTheme;
      final enabledBorder = input.enabledBorder! as OutlineInputBorder;

      expect(theme.brightness, Brightness.dark, reason: role);
      expect(input.fillColor, scheme.surfaceContainerHigh, reason: role);
      expect(input.labelStyle!.color, scheme.onSurfaceVariant, reason: role);
      expect(input.hintStyle!.color, scheme.onSurfaceVariant, reason: role);
      expect(input.helperStyle!.color, scheme.onSurfaceVariant, reason: role);
      expect(input.errorStyle!.color, scheme.error, reason: role);
      expect(input.prefixIconColor, scheme.onSurfaceVariant, reason: role);
      expect(input.suffixIconColor, scheme.onSurfaceVariant, reason: role);
      expect(enabledBorder.borderSide.color, scheme.outline, reason: role);

      final chip = theme.chipTheme;
      expect(
        chip.color!.resolve(_noStates),
        scheme.surfaceContainerHigh,
        reason: role,
      );
      expect(
        chip.color!.resolve(_selected),
        scheme.primaryContainer,
        reason: role,
      );
      expect(chip.labelStyle!.color, scheme.onSurface, reason: role);
      expect(
        chip.secondaryLabelStyle!.color,
        scheme.onPrimaryContainer,
        reason: role,
      );

      final segmentedStyle = theme.segmentedButtonTheme.style!;
      expect(
        segmentedStyle.backgroundColor!.resolve(_noStates),
        scheme.surfaceContainerHigh,
        reason: role,
      );
      expect(
        segmentedStyle.backgroundColor!.resolve(_selected),
        scheme.primaryContainer,
        reason: role,
      );
      expect(
        segmentedStyle.foregroundColor!.resolve(_noStates),
        scheme.onSurfaceVariant,
        reason: role,
      );
      expect(
        segmentedStyle.foregroundColor!.resolve(_selected),
        scheme.onPrimaryContainer,
        reason: role,
      );

      expect(theme.listTileTheme.textColor, scheme.onSurface, reason: role);
      expect(
        theme.listTileTheme.subtitleTextStyle!.color,
        scheme.onSurfaceVariant,
        reason: role,
      );
      expect(
        theme.expansionTileTheme.backgroundColor,
        scheme.secondaryContainer,
        reason: role,
      );
      expect(
        theme.expansionTileTheme.textColor,
        scheme.onSecondaryContainer,
        reason: role,
      );

      final tableDecoration = theme.dataTableTheme.decoration! as BoxDecoration;
      expect(tableDecoration.color, scheme.surface, reason: role);
      expect(
        theme.dataTableTheme.headingRowColor!.resolve(_noStates),
        scheme.secondaryContainer,
        reason: role,
      );
      expect(
        theme.dataTableTheme.headingTextStyle!.color,
        scheme.onSecondaryContainer,
        reason: role,
      );

      expect(theme.dividerTheme.color, scheme.outlineVariant, reason: role);
      expect(theme.popupMenuTheme.color, scheme.surface, reason: role);
      expect(
        theme.popupMenuTheme.textStyle!.color,
        scheme.onSurface,
        reason: role,
      );
      expect(
        theme.datePickerTheme.backgroundColor,
        scheme.surface,
        reason: role,
      );
      expect(
        theme.datePickerTheme.dayForegroundColor!.resolve(_noStates),
        scheme.onSurface,
        reason: role,
      );
      expect(
        theme.datePickerTheme.dayBackgroundColor!.resolve(_selected),
        scheme.primary,
        reason: role,
      );
      expect(
        theme.datePickerTheme.dayForegroundColor!.resolve(_selected),
        scheme.onPrimary,
        reason: role,
      );

      expect(
        theme.switchTheme.trackColor!.resolve(_selected),
        scheme.primary,
        reason: role,
      );
      expect(
        theme.switchTheme.thumbColor!.resolve(_selected),
        scheme.onPrimary,
        reason: role,
      );
      expect(
        theme.checkboxTheme.fillColor!.resolve(_selected),
        scheme.primary,
        reason: role,
      );
      expect(
        theme.checkboxTheme.checkColor!.resolve(_selected),
        scheme.onPrimary,
        reason: role,
      );
      expect(
        theme.radioTheme.fillColor!.resolve(_selected),
        scheme.primary,
        reason: role,
      );
      expect(theme.progressIndicatorTheme.color, scheme.primary, reason: role);
      expect(
        theme.progressIndicatorTheme.linearTrackColor,
        scheme.surfaceContainerHighest,
        reason: role,
      );
    }
  });

  test('dark foreground and background pairs meet WCAG contrast', () {
    for (final entry in darkThemes.entries) {
      final role = entry.key;
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final input = theme.inputDecorationTheme;
      final inputSurface = input.fillColor!;
      final semanticColors = theme.extension<AppSemanticColors>()!;

      _expectContrast(scheme.onSurface, inputSurface, 4.5, '$role input value');
      _expectContrast(
        input.labelStyle!.color!,
        inputSurface,
        4.5,
        '$role input label',
      );
      _expectContrast(
        input.errorStyle!.color!,
        inputSurface,
        4.5,
        '$role input error',
      );
      _expectContrast(
        (input.enabledBorder! as OutlineInputBorder).borderSide.color,
        inputSurface,
        3,
        '$role input outline',
      );

      final filledStyle = theme.filledButtonTheme.style!;
      _expectContrast(
        filledStyle.foregroundColor!.resolve(_noStates)!,
        filledStyle.backgroundColor!.resolve(_noStates)!,
        4.5,
        '$role filled button',
      );

      final navigation = theme.navigationBarTheme;
      _expectContrast(
        navigation.labelTextStyle!.resolve(_noStates)!.color!,
        navigation.backgroundColor!,
        4.5,
        '$role navigation label',
      );
      _expectContrast(
        navigation.labelTextStyle!.resolve(_selected)!.color!,
        navigation.indicatorColor!,
        4.5,
        '$role selected navigation label',
      );

      final chip = theme.chipTheme;
      _expectContrast(
        chip.labelStyle!.color!,
        chip.color!.resolve(_noStates)!,
        4.5,
        '$role chip',
      );
      _expectContrast(
        chip.secondaryLabelStyle!.color!,
        chip.color!.resolve(_selected)!,
        4.5,
        '$role selected chip',
      );

      final segmentedStyle = theme.segmentedButtonTheme.style!;
      _expectContrast(
        segmentedStyle.foregroundColor!.resolve(_noStates)!,
        segmentedStyle.backgroundColor!.resolve(_noStates)!,
        4.5,
        '$role segmented button',
      );
      _expectContrast(
        segmentedStyle.foregroundColor!.resolve(_selected)!,
        segmentedStyle.backgroundColor!.resolve(_selected)!,
        4.5,
        '$role selected segmented button',
      );

      _expectContrast(
        theme.expansionTileTheme.textColor!,
        theme.expansionTileTheme.backgroundColor!,
        4.5,
        '$role expansion tile',
      );
      _expectContrast(
        theme.dataTableTheme.headingTextStyle!.color!,
        theme.dataTableTheme.headingRowColor!.resolve(_noStates)!,
        4.5,
        '$role data table heading',
      );
      _expectContrast(
        theme.popupMenuTheme.textStyle!.color!,
        theme.popupMenuTheme.color!,
        4.5,
        '$role popup menu',
      );
      _expectContrast(
        theme.datePickerTheme.dayForegroundColor!.resolve(_selected)!,
        theme.datePickerTheme.dayBackgroundColor!.resolve(_selected)!,
        4.5,
        '$role selected date',
      );

      final tooltipDecoration = theme.tooltipTheme.decoration! as BoxDecoration;
      _expectContrast(
        theme.tooltipTheme.textStyle!.color!,
        tooltipDecoration.color!,
        4.5,
        '$role tooltip',
      );
      _expectContrast(
        theme.snackBarTheme.contentTextStyle!.color!,
        theme.snackBarTheme.backgroundColor!,
        4.5,
        '$role snackbar',
      );
      _expectContrast(
        semanticColors.onSuccess,
        semanticColors.success,
        4.5,
        '$role success',
      );
      _expectContrast(
        semanticColors.onSuccessContainer,
        semanticColors.successContainer,
        4.5,
        '$role success container',
      );
      _expectContrast(
        semanticColors.onWarning,
        semanticColors.warning,
        4.5,
        '$role warning',
      );
      _expectContrast(
        semanticColors.onWarningContainer,
        semanticColors.warningContainer,
        4.5,
        '$role warning container',
      );
      _expectContrast(
        semanticColors.onInfo,
        semanticColors.info,
        4.5,
        '$role info',
      );
      _expectContrast(
        semanticColors.onInfoContainer,
        semanticColors.infoContainer,
        4.5,
        '$role info container',
      );
    }
  });

  testWidgets('common widgets memakai semantic dark surfaces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cashier(true),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                AppDropdownField<String>(
                  initialValue: 'tunai',
                  decoration: const InputDecoration(labelText: 'Pembayaran'),
                  items: const [
                    DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
                  ],
                  onChanged: (_) {},
                ),
                const AppSectionCard(
                  key: Key('section'),
                  child: Text('Ringkasan'),
                ),
                const AppStatusBadge(
                  key: Key('status'),
                  label: 'Selesai',
                  status: AppStatus.success,
                ),
                FilledButton(
                  onPressed: () => AppAlert.show(
                    context,
                    'Pembayaran tersimpan',
                    type: AppAlertType.success,
                  ),
                  child: const Text('Tampilkan alert'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(dropdown.dropdownColor, AppColors.darkContainerHigh);

    final sectionContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('section')),
            matching: find.byType(Container),
          )
          .first,
    );
    final sectionDecoration = sectionContainer.decoration! as BoxDecoration;
    expect(sectionDecoration.color, AppColors.darkContainerLow);

    final statusBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const Key('status')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final statusDecoration = statusBox.decoration as BoxDecoration;
    expect(statusDecoration.color, AppColors.darkSuccessContainer);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await tester.tap(find.text('Tampilkan alert'));
    await tester.pump();
    final alert = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(alert.backgroundColor, AppColors.darkSuccessContainer);
  });

  test('light component colors keep the Talaga visual baseline', () {
    final lightThemes = <ThemeData>[
      AppTheme.guest(false),
      AppTheme.cashier(false),
      AppTheme.admin(false),
    ];

    for (final theme in lightThemes) {
      final scheme = theme.colorScheme;

      expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
      expect(theme.inputDecorationTheme.labelStyle!.color, AppColors.inkMuted);
      expect(
        (theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
            .borderSide
            .color,
        AppColors.outline,
      );
      expect(theme.dividerTheme.color, AppColors.outline);
      expect(theme.popupMenuTheme.color, AppColors.surface);
      expect(theme.datePickerTheme.backgroundColor, AppColors.surface);
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve(_noStates),
        scheme.primary,
      );
      expect(
        theme.filledButtonTheme.style!.foregroundColor!.resolve(_noStates),
        AppColors.white,
      );
    }

    expect(lightThemes[1].colorScheme.primary, AppColors.lake700);
    expect(lightThemes[2].colorScheme.primary, AppColors.wood700);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectContrast(
  Color foreground,
  Color background,
  double minimum,
  String context,
) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(minimum),
    reason: '$context contrast is below $minimum:1',
  );
}
