import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_shadows.dart';

enum AppSectionTone { warm, lake, neutral, attention, plain }

/// Surface section semantik dengan warna, border, dan padding dari design token.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.tone = AppSectionTone.neutral,
  });

  final Widget child;
  final AppSectionTone tone;

  @override
  Widget build(BuildContext context) {
    final roleTokens = AppRoleTokens.of(context);
    final baseTheme = Theme.of(context);
    final style = _styleFor(tone, baseTheme);
    final localTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        surface: style.background,
        onSurface: style.foreground,
        onSurfaceVariant: style.foreground,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: style.foreground,
        displayColor: style.foreground,
      ),
      iconTheme: baseTheme.iconTheme.copyWith(color: style.foreground),
      listTileTheme: baseTheme.listTileTheme.copyWith(
        textColor: style.foreground,
        iconColor: style.foreground,
      ),
    );

    return Theme(
      data: localTheme,
      child: Container(
        padding: EdgeInsets.all(roleTokens.cardPadding),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: style.background,
          border: Border.all(color: style.border),
          borderRadius: AppRadius.card,
          boxShadow: style.shadows,
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  static _SectionStyle _styleFor(AppSectionTone tone, ThemeData theme) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return switch (tone) {
      AppSectionTone.warm => _SectionStyle(
        background: isDark ? AppColors.wood800 : AppColors.cream100,
        foreground: isDark ? AppColors.cream100 : AppColors.ink,
        border: AppColors.wood400,
        shadows: isDark ? AppShadows.none : AppShadows.surface,
      ),
      AppSectionTone.lake => _SectionStyle(
        background: isDark ? AppColors.lake800 : AppColors.lake100,
        foreground: isDark ? AppColors.lake100 : AppColors.ink,
        border: isDark ? AppColors.lake400 : AppColors.lake300,
        shadows: isDark ? AppShadows.none : AppShadows.lakeGlow,
      ),
      AppSectionTone.neutral => _SectionStyle(
        background: isDark ? scheme.surfaceContainerLow : scheme.surface,
        foreground: scheme.onSurface,
        border: scheme.outlineVariant,
        shadows: isDark ? AppShadows.none : AppShadows.surface,
      ),
      AppSectionTone.attention => _SectionStyle(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        border: scheme.error,
        shadows: isDark ? AppShadows.none : AppShadows.surface,
      ),
      AppSectionTone.plain => _SectionStyle(
        background: scheme.surface,
        foreground: scheme.onSurface,
        border: scheme.outlineVariant,
        shadows: AppShadows.none,
      ),
    };
  }
}

class _SectionStyle {
  const _SectionStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.shadows,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final List<BoxShadow> shadows;
}
