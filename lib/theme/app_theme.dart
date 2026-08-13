import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_layout.dart';
import 'app_radius.dart';
import 'app_role_tokens.dart';
import 'app_semantic_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Theme "Tepi Talaga" untuk setiap konteks kerja aplikasi.
abstract final class AppTheme {
  static ThemeData guest(bool isDark) => _build(_ThemeConfig.guest, isDark);
  static ThemeData cashier(bool isDark) => _build(_ThemeConfig.cashier, isDark);
  static ThemeData admin(bool isDark) => _build(_ThemeConfig.admin, isDark);

  /// Menerapkan skala tipografi dari available width tanpa mengubah role,
  /// brightness, atau component theme lain pada [base].
  static ThemeData responsive(ThemeData base, double width) {
    final scheme = base.colorScheme;
    final appBarForeground =
        base.appBarTheme.foregroundColor ??
        base.primaryTextTheme.bodyMedium?.color ??
        scheme.onPrimary;
    final responsiveTextTheme = AppTypography.textThemeForWidth(width);

    return base.copyWith(
      textTheme: responsiveTextTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      primaryTextTheme: responsiveTextTheme.apply(
        bodyColor: appBarForeground,
        displayColor: appBarForeground,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: responsiveTextTheme.titleMedium?.copyWith(
          color: appBarForeground,
        ),
      ),
    );
  }

  static ThemeData _build(_ThemeConfig config, bool isDark) {
    final scheme = _colorScheme(config, isDark);
    final role = config.tokens;
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[role, semanticColors],
      scaffoldBackgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      canvasColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      cardColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      disabledColor: _disabledForeground(scheme),
      focusColor: _focusColor(config, scheme),
      hoverColor: scheme.onSurface.withValues(alpha: 0.06),
      highlightColor: AppColors.transparent,
      splashColor: scheme.onSurface.withValues(alpha: 0.12),
      shadowColor: isDark ? AppColors.transparent : AppColors.shadowWoodSurface,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: isDark ? scheme.onPrimaryContainer : config.onMasthead,
        displayColor: isDark ? scheme.onPrimaryContainer : config.onMasthead,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      primaryIconTheme: IconThemeData(
        color: isDark ? scheme.onPrimaryContainer : config.onMasthead,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: _appBarTheme(config, scheme),
      cardTheme: _cardTheme(scheme, isDark),
      dialogTheme: _dialogTheme(scheme, isDark),
      bottomSheetTheme: _bottomSheetTheme(scheme, isDark),
      drawerTheme: _drawerTheme(scheme, isDark),
      navigationBarTheme: _navigationBarTheme(config, scheme),
      navigationDrawerTheme: _navigationDrawerTheme(config, scheme),
      inputDecorationTheme: _inputTheme(config, scheme),
      filledButtonTheme: _filledButtonTheme(config, scheme),
      outlinedButtonTheme: _outlinedButtonTheme(config, scheme),
      textButtonTheme: _textButtonTheme(config, scheme),
      iconButtonTheme: _iconButtonTheme(config, scheme),
      floatingActionButtonTheme: _floatingActionButtonTheme(config, scheme),
      chipTheme: _chipTheme(config, scheme),
      segmentedButtonTheme: _segmentedButtonTheme(config, scheme),
      listTileTheme: _listTileTheme(config, scheme),
      expansionTileTheme: _expansionTileTheme(config, scheme),
      dataTableTheme: _dataTableTheme(config, scheme),
      dividerTheme: _dividerTheme(scheme),
      switchTheme: _switchTheme(config, scheme),
      checkboxTheme: _checkboxTheme(config, scheme),
      radioTheme: _radioTheme(config, scheme),
      progressIndicatorTheme: _progressIndicatorTheme(config, scheme),
      snackBarTheme: _snackBarTheme(config, scheme),
      tooltipTheme: _tooltipTheme(scheme),
      popupMenuTheme: _popupMenuTheme(scheme),
      datePickerTheme: _datePickerTheme(config, scheme),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  static ColorScheme _colorScheme(_ThemeConfig config, bool isDark) {
    if (isDark) {
      final isCashier = config.tokens.isCashier;
      return ColorScheme(
        brightness: Brightness.dark,
        primary: isCashier ? AppColors.lake300 : AppColors.clay300,
        onPrimary: isCashier ? AppColors.lake950 : AppColors.wood950,
        primaryContainer: isCashier ? AppColors.lake800 : AppColors.wood800,
        onPrimaryContainer: isCashier ? AppColors.lake100 : AppColors.cream100,
        secondary: isCashier ? AppColors.clay300 : AppColors.lake400,
        onSecondary: isCashier ? AppColors.wood950 : AppColors.lake950,
        secondaryContainer: isCashier ? AppColors.wood800 : AppColors.lake800,
        onSecondaryContainer: isCashier
            ? AppColors.cream100
            : AppColors.lake100,
        tertiary: AppColors.darkWarning,
        onTertiary: AppColors.darkOnWarning,
        tertiaryContainer: AppColors.darkWarningContainer,
        onTertiaryContainer: AppColors.darkOnWarningContainer,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: AppColors.darkOnErrorContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceDim: AppColors.darkSurfaceDim,
        surfaceBright: AppColors.darkSurfaceBright,
        surfaceContainerLowest: AppColors.darkContainerLowest,
        surfaceContainerLow: AppColors.darkContainerLow,
        surfaceContainer: AppColors.darkContainer,
        surfaceContainerHigh: AppColors.darkContainerHigh,
        surfaceContainerHighest: AppColors.darkContainerHighest,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        shadow: AppColors.transparent,
        scrim: AppColors.darkScrim,
        inverseSurface: AppColors.darkInverseSurface,
        onInverseSurface: AppColors.darkOnInverseSurface,
        inversePrimary: config.primary,
        surfaceTint: AppColors.transparent,
      );
    }

    return ColorScheme(
      brightness: Brightness.light,
      primary: config.primary,
      onPrimary: AppColors.white,
      primaryContainer: config.selectedSurface,
      onPrimaryContainer: AppColors.ink,
      secondary: config.secondary,
      onSecondary: AppColors.white,
      secondaryContainer: config.secondarySurface,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.ochre,
      onTertiary: AppColors.wood950,
      tertiaryContainer: AppColors.ochreSoft,
      onTertiaryContainer: AppColors.wood950,
      error: AppColors.terracotta,
      onError: AppColors.white,
      errorContainer: AppColors.terracottaSoft,
      onErrorContainer: AppColors.terracottaDark,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceDim: AppColors.surfaceMuted,
      surfaceBright: AppColors.surface,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.cream100,
      surfaceContainer: AppColors.surfaceMuted,
      surfaceContainerHigh: config.secondarySurface,
      surfaceContainerHighest: config.selectedSurface,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.outlineStrong,
      outlineVariant: AppColors.outline,
      shadow: AppColors.wood950,
      scrim: AppColors.scrim,
      inverseSurface: config.masthead,
      onInverseSurface: config.onMasthead,
      inversePrimary: config.secondarySurface,
      surfaceTint: AppColors.transparent,
    );
  }

  static bool _isDark(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark;

  static Color _controlSurface(ColorScheme scheme) =>
      _isDark(scheme) ? scheme.surfaceContainerHigh : scheme.surface;

  static Color _disabledContainer(ColorScheme scheme) =>
      scheme.surfaceContainer;

  static Color _controlOutline(ColorScheme scheme) =>
      _isDark(scheme) ? scheme.outline : scheme.outlineVariant;

  static Color _disabledForeground(ColorScheme scheme) => _isDark(scheme)
      ? scheme.onSurface.withValues(alpha: 0.38)
      : AppColors.disabledInk;

  static double _interactiveHeight(AppRoleTokens tokens) =>
      tokens.controlHeight < tokens.minTapTarget
      ? tokens.minTapTarget
      : tokens.controlHeight;

  static Color _selectedForeground(_ThemeConfig config, ColorScheme scheme) =>
      _isDark(scheme) ? scheme.onPrimaryContainer : config.primary;

  static Color _focusColor(_ThemeConfig config, ColorScheme scheme) =>
      _isDark(scheme)
      ? config.darkFocusBorder.withValues(alpha: 0.28)
      : config.focus;

  static Color _focusBorder(_ThemeConfig config, ColorScheme scheme) =>
      _isDark(scheme) ? config.darkFocusBorder : config.focusBorder;

  static Color _primaryPressed(_ThemeConfig config, ColorScheme scheme) =>
      _isDark(scheme)
      ? Color.alphaBlend(AppColors.pressedWhiteOverlay, scheme.primary)
      : config.primaryPressed;

  static Color _primaryHover(_ThemeConfig config, ColorScheme scheme) =>
      _isDark(scheme)
      ? Color.alphaBlend(AppColors.hoverWhiteOverlay, scheme.primary)
      : config.primaryHover;

  static AppBarThemeData _appBarTheme(_ThemeConfig config, ColorScheme scheme) {
    final isDark = _isDark(scheme);
    final background = isDark ? scheme.primaryContainer : config.masthead;
    final foreground = isDark ? scheme.onPrimaryContainer : config.onMasthead;
    final statusBarIconBrightness = background.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;
    return AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: config.tokens.isAdmin
          ? AppLayout.adminMastheadHeight
          : AppLayout.cashierServiceBarHeight,
      backgroundColor: background,
      foregroundColor: foreground,
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.transparent,
      titleTextStyle: AppTypography.title.copyWith(color: foreground),
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: scheme.outlineVariant,
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme, bool isDark) =>
      CardThemeData(
        elevation: 0,
        margin: AppSpacing.zero,
        color: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        shadowColor: isDark
            ? AppColors.transparent
            : AppColors.shadowWoodSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      );

  static DialogThemeData _dialogTheme(
    ColorScheme scheme,
    bool isDark,
  ) => DialogThemeData(
    elevation: AppShadows.floatingElevation,
    backgroundColor: scheme.surface,
    surfaceTintColor: AppColors.transparent,
    shadowColor: isDark ? AppColors.transparent : AppColors.shadowWoodFloating,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.dialog,
      side: BorderSide(color: scheme.outlineVariant),
    ),
    titleTextStyle: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
    contentTextStyle: AppTypography.body.copyWith(color: scheme.onSurface),
  );

  static BottomSheetThemeData _bottomSheetTheme(
    ColorScheme scheme,
    bool isDark,
  ) => BottomSheetThemeData(
    backgroundColor: scheme.surface,
    modalBackgroundColor: scheme.surface,
    surfaceTintColor: AppColors.transparent,
    shadowColor: isDark ? AppColors.transparent : AppColors.shadowWoodFloating,
    elevation: AppShadows.floatingElevation,
    modalElevation: AppShadows.floatingElevation,
    showDragHandle: true,
    dragHandleColor: scheme.outline,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    constraints: const BoxConstraints(maxWidth: AppLayout.dialogLargeMaxWidth),
  );

  static DrawerThemeData _drawerTheme(ColorScheme scheme, bool isDark) =>
      DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppShadows.floatingElevation,
        shadowColor: isDark
            ? AppColors.transparent
            : AppColors.shadowWoodFloating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.lg),
          ),
        ),
      );

  static NavigationBarThemeData _navigationBarTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return NavigationBarThemeData(
      height: config.tokens.isCashier
          ? AppLayout.cashierBottomDockHeight
          : AppLayout.cashierServiceBarHeight,
      elevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: AppColors.transparent,
      shadowColor: _isDark(scheme)
          ? scheme.shadow
          : AppColors.shadowWoodFloating,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: AppRadius.card,
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return IconThemeData(color: _disabledForeground(scheme));
        }
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: _selectedForeground(config, scheme));
        }
        return IconThemeData(color: scheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? _selectedForeground(config, scheme)
            : states.contains(WidgetState.disabled)
            ? _disabledForeground(scheme)
            : scheme.onSurfaceVariant;
        return AppTypography.label.copyWith(color: color);
      }),
    );
  }

  static NavigationDrawerThemeData _navigationDrawerTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return NavigationDrawerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shadowColor: _isDark(scheme)
          ? scheme.shadow
          : AppColors.shadowWoodFloating,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: AppRadius.input,
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? _selectedForeground(config, scheme)
              : scheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return AppTypography.bodyStrong.copyWith(
          color: states.contains(WidgetState.selected)
              ? _selectedForeground(config, scheme)
              : scheme.onSurface,
        );
      }),
    );
  }

  static InputDecorationThemeData _inputTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return InputDecorationThemeData(
      filled: true,
      fillColor: _controlSurface(scheme),
      isDense: config.tokens.isAdmin,
      constraints: BoxConstraints(minHeight: config.tokens.controlHeight),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelStyle: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: AppTypography.label.copyWith(color: scheme.primary),
      hintStyle: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: AppTypography.caption.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      errorStyle: AppTypography.caption.copyWith(color: scheme.error),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      border: _inputBorder(_controlOutline(scheme)),
      enabledBorder: _inputBorder(_controlOutline(scheme)),
      disabledBorder: _inputBorder(scheme.outlineVariant),
      focusedBorder: _inputBorder(_focusBorder(config, scheme), width: 2),
      errorBorder: _inputBorder(scheme.error),
      focusedErrorBorder: _inputBorder(scheme.error, width: 2),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.input,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSpacing.none, config.tokens.primaryControlHeight),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: const WidgetStatePropertyAll(AppTypography.bodyStrong),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _disabledContainer(scheme);
          }
          if (states.contains(WidgetState.pressed)) {
            return _primaryPressed(config, scheme);
          }
          if (states.contains(WidgetState.hovered)) {
            return _primaryHover(config, scheme);
          }
          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? _disabledForeground(scheme)
              : scheme.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.pressedWhiteOverlay;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.hoverWhiteOverlay;
          }
          return AppColors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.focused)
                ? _focusBorder(config, scheme)
                : AppColors.transparent,
            width: 2,
          );
        }),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSpacing.none, config.tokens.controlHeight),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: const WidgetStatePropertyAll(AppTypography.bodyStrong),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? _disabledForeground(scheme)
              : scheme.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _disabledContainer(scheme);
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.selected)) {
            return scheme.primaryContainer;
          }
          return AppColors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.focused)
                ? _focusBorder(config, scheme)
                : states.contains(WidgetState.disabled)
                ? scheme.outlineVariant
                : scheme.primary,
            width: states.contains(WidgetState.focused) ? 2 : 1,
          );
        }),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSpacing.none, config.tokens.controlHeight),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.input),
        ),
        textStyle: const WidgetStatePropertyAll(AppTypography.bodyStrong),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? _disabledForeground(scheme)
              : scheme.primary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? scheme.primaryContainer
              : AppColors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),
    );
  }

  static IconButtonThemeData _iconButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size.square(config.tokens.minTapTarget),
        ),
        iconSize: WidgetStatePropertyAll(
          config.tokens.isCashier ? AppSpacing.xl : AppSpacing.lg,
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.input),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _disabledForeground(scheme);
          }
          if (states.contains(WidgetState.selected)) {
            return _selectedForeground(config, scheme);
          }
          return scheme.onSurface;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected) ||
              states.contains(WidgetState.pressed)) {
            return scheme.primaryContainer;
          }
          return AppColors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        side: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.transparent, width: 2);
          }
          return BorderSide(color: _focusBorder(config, scheme), width: 2);
        }),
      ),
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return FloatingActionButtonThemeData(
      elevation: AppShadows.surfaceElevation,
      focusElevation: AppShadows.surfaceElevation,
      hoverElevation: AppShadows.floatingElevation,
      highlightElevation: AppShadows.surfaceElevation,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      focusColor: _focusColor(config, scheme),
      hoverColor: _primaryHover(config, scheme),
      splashColor: _primaryPressed(config, scheme),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
    );
  }

  static ChipThemeData _chipTheme(_ThemeConfig config, ColorScheme scheme) {
    return ChipThemeData(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledContainer(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primaryContainer;
        }
        if (states.contains(WidgetState.pressed)) {
          return scheme.secondaryContainer;
        }
        return _controlSurface(scheme);
      }),
      surfaceTintColor: AppColors.transparent,
      shadowColor: AppColors.transparent,
      selectedShadowColor: AppColors.transparent,
      showCheckmark: true,
      checkmarkColor: _selectedForeground(config, scheme),
      side: BorderSide(color: _controlOutline(scheme)),
      shape: const StadiumBorder(),
      labelStyle: AppTypography.label.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: AppTypography.label.copyWith(
        color: _selectedForeground(config, scheme),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      pressElevation: 0,
    );
  }

  static SegmentedButtonThemeData _segmentedButtonTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSpacing.none, config.tokens.controlHeight),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.chip),
        ),
        textStyle: const WidgetStatePropertyAll(AppTypography.bodyStrong),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _disabledForeground(scheme);
          }
          return states.contains(WidgetState.selected)
              ? _selectedForeground(config, scheme)
              : scheme.onSurfaceVariant;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _disabledContainer(scheme);
          }
          return states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : _controlSurface(scheme);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.focused)
                ? _focusBorder(config, scheme)
                : states.contains(WidgetState.selected)
                ? scheme.primary
                : _controlOutline(scheme),
            width: states.contains(WidgetState.focused) ? 2 : 1,
          );
        }),
      ),
    );
  }

  static ListTileThemeData _listTileTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      minTileHeight: _interactiveHeight(config.tokens),
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      selectedColor: _selectedForeground(config, scheme),
      selectedTileColor: scheme.primaryContainer,
      titleTextStyle: AppTypography.bodyStrong.copyWith(
        color: scheme.onSurface,
      ),
      subtitleTextStyle: AppTypography.caption.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
    );
  }

  static ExpansionTileThemeData _expansionTileTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return ExpansionTileThemeData(
      backgroundColor: scheme.secondaryContainer,
      collapsedBackgroundColor: scheme.surface,
      textColor: _isDark(scheme) ? scheme.onSecondaryContainer : config.primary,
      collapsedTextColor: scheme.onSurface,
      iconColor: _isDark(scheme) ? scheme.onSecondaryContainer : config.primary,
      collapsedIconColor: scheme.onSurfaceVariant,
      tilePadding: AppSpacing.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
      collapsedShape: const RoundedRectangleBorder(
        borderRadius: AppRadius.input,
      ),
    );
  }

  static DataTableThemeData _dataTableTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return DataTableThemeData(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.fromBorderSide(BorderSide(color: scheme.outlineVariant)),
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primaryContainer;
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.secondaryContainer;
        }
        return scheme.surface;
      }),
      headingRowColor: WidgetStatePropertyAll(scheme.secondaryContainer),
      dataRowMinHeight: _interactiveHeight(config.tokens),
      dataRowMaxHeight: _interactiveHeight(config.tokens) + AppSpacing.sm,
      headingRowHeight: config.tokens.primaryControlHeight,
      dataTextStyle: AppTypography.body.copyWith(color: scheme.onSurface),
      headingTextStyle: AppTypography.label.copyWith(
        color: _isDark(scheme) ? scheme.onSecondaryContainer : config.primary,
      ),
      horizontalMargin: AppSpacing.md,
      columnSpacing: AppSpacing.xl,
      dividerThickness: 1,
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme scheme) => DividerThemeData(
    color: scheme.outlineVariant,
    thickness: 1,
    space: AppSpacing.md,
  );

  static SwitchThemeData _switchTheme(_ThemeConfig config, ColorScheme scheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledForeground(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimary;
        }
        return scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledContainer(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return _isDark(scheme)
            ? scheme.surfaceContainerHighest
            : AppColors.outline;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.focused)
            ? _focusBorder(config, scheme)
            : AppColors.transparent;
      }),
      overlayColor: WidgetStatePropertyAll(_focusColor(config, scheme)),
    );
  }

  static CheckboxThemeData _checkboxTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.badge),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledContainer(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return _controlSurface(scheme);
      }),
      checkColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled)
            ? _disabledForeground(scheme)
            : scheme.onPrimary;
      }),
      side: BorderSide(color: scheme.outline, width: 2),
      overlayColor: WidgetStatePropertyAll(_focusColor(config, scheme)),
    );
  }

  static RadioThemeData _radioTheme(_ThemeConfig config, ColorScheme scheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledForeground(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return scheme.onSurfaceVariant;
      }),
      overlayColor: WidgetStatePropertyAll(_focusColor(config, scheme)),
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: _isDark(scheme)
          ? scheme.surfaceContainerHighest
          : config.secondarySurface,
      circularTrackColor: _isDark(scheme)
          ? scheme.surfaceContainerHighest
          : config.secondarySurface,
    );
  }

  static SnackBarThemeData _snackBarTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: scheme.inverseSurface,
      actionTextColor: _isDark(scheme)
          ? scheme.inversePrimary
          : config.tokens.isAdmin
          ? AppColors.lake300
          : AppColors.clay300,
      disabledActionTextColor: _isDark(scheme)
          ? _disabledForeground(scheme)
          : AppColors.disabledInk,
      contentTextStyle: AppTypography.body.copyWith(
        color: scheme.onInverseSurface,
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
    );
  }

  static TooltipThemeData _tooltipTheme(ColorScheme scheme) => TooltipThemeData(
    decoration: BoxDecoration(
      color: _isDark(scheme) ? scheme.inverseSurface : AppColors.wood950,
      borderRadius: AppRadius.input,
    ),
    textStyle: AppTypography.caption.copyWith(
      color: _isDark(scheme) ? scheme.onInverseSurface : AppColors.white,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    margin: const EdgeInsets.all(AppSpacing.xs),
  );

  static PopupMenuThemeData _popupMenuTheme(ColorScheme scheme) =>
      PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: AppShadows.floatingElevation,
        shadowColor: _isDark(scheme)
            ? scheme.shadow
            : AppColors.shadowWoodFloating,
        textStyle: AppTypography.body.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      );

  static DatePickerThemeData _datePickerTheme(
    _ThemeConfig config,
    ColorScheme scheme,
  ) {
    return DatePickerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: AppColors.transparent,
      shadowColor: _isDark(scheme)
          ? scheme.shadow
          : AppColors.shadowWoodFloating,
      headerBackgroundColor: _isDark(scheme)
          ? scheme.surfaceContainerHighest
          : config.masthead,
      headerForegroundColor: _isDark(scheme)
          ? scheme.onSurface
          : config.onMasthead,
      rangeSelectionBackgroundColor: scheme.primaryContainer,
      rangeSelectionOverlayColor: WidgetStatePropertyAll(
        _focusColor(config, scheme),
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return AppColors.transparent;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledForeground(scheme);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimary;
        }
        return scheme.onSurface;
      }),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      rangePickerShape: const RoundedRectangleBorder(
        borderRadius: AppRadius.dialog,
      ),
    );
  }
}

@immutable
class _ThemeConfig {
  const _ThemeConfig({
    required this.tokens,
    required this.primary,
    required this.primaryPressed,
    required this.primaryHover,
    required this.secondary,
    required this.selectedSurface,
    required this.secondarySurface,
    required this.masthead,
    required this.onMasthead,
    required this.focus,
    required this.focusBorder,
    required this.darkFocusBorder,
  });

  static const guest = _ThemeConfig(
    tokens: AppRoleTokens.guest,
    primary: AppColors.wood700,
    primaryPressed: AppColors.wood800,
    primaryHover: AppColors.wood600,
    secondary: AppColors.lake700,
    selectedSurface: AppColors.cream100,
    secondarySurface: AppColors.lake100,
    masthead: AppColors.surface,
    onMasthead: AppColors.ink,
    focus: AppColors.woodFocus,
    focusBorder: AppColors.wood400,
    darkFocusBorder: AppColors.wood400,
  );

  static const cashier = _ThemeConfig(
    tokens: AppRoleTokens.cashier,
    primary: AppColors.lake700,
    primaryPressed: AppColors.lake800,
    primaryHover: AppColors.lake600,
    secondary: AppColors.wood600,
    selectedSurface: AppColors.lake100,
    secondarySurface: AppColors.cream100,
    masthead: AppColors.lake950,
    onMasthead: AppColors.white,
    focus: AppColors.lakeFocus,
    focusBorder: AppColors.lake400,
    darkFocusBorder: AppColors.lake400,
  );

  static const admin = _ThemeConfig(
    tokens: AppRoleTokens.admin,
    primary: AppColors.wood700,
    primaryPressed: AppColors.wood800,
    primaryHover: AppColors.wood600,
    secondary: AppColors.lake600,
    selectedSurface: AppColors.cream100,
    secondarySurface: AppColors.lake100,
    masthead: AppColors.wood950,
    onMasthead: AppColors.white,
    focus: AppColors.woodFocus,
    focusBorder: AppColors.wood400,
    darkFocusBorder: AppColors.wood400,
  );

  final AppRoleTokens tokens;
  final Color primary;
  final Color primaryPressed;
  final Color primaryHover;
  final Color secondary;
  final Color selectedSurface;
  final Color secondarySurface;
  final Color masthead;
  final Color onMasthead;
  final Color focus;
  final Color focusBorder;
  final Color darkFocusBorder;
}
