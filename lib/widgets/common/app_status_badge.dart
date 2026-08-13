import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';

enum AppStatus { success, warning, danger, info, neutral }

/// Badge status yang menerima arti semantik, bukan warna bebas.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
    this.icon,
  });

  final String label;
  final AppStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _styleFor(
      status,
      theme.colorScheme,
      AppSemanticColors.of(context),
    );
    final effectiveIcon = icon ?? _defaultIcon(status);

    return Semantics(
      container: true,
      label: 'Status: $label',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: AppRadius.chip,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(effectiveIcon, color: style.foreground, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: style.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _defaultIcon(AppStatus status) {
    return switch (status) {
      AppStatus.success => Icons.check_circle_outline,
      AppStatus.warning => Icons.warning_amber_outlined,
      AppStatus.danger => Icons.error_outline,
      AppStatus.info => Icons.info_outline,
      AppStatus.neutral => Icons.circle_outlined,
    };
  }

  static _BadgeStyle _styleFor(
    AppStatus status,
    ColorScheme scheme,
    AppSemanticColors semanticColors,
  ) {
    return switch (status) {
      AppStatus.success => _BadgeStyle(
        background: semanticColors.successContainer,
        foreground: semanticColors.onSuccessContainer,
      ),
      AppStatus.warning => _BadgeStyle(
        background: semanticColors.warningContainer,
        foreground: semanticColors.onWarningContainer,
      ),
      AppStatus.danger => _BadgeStyle(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      AppStatus.info => _BadgeStyle(
        background: semanticColors.infoContainer,
        foreground: semanticColors.onInfoContainer,
      ),
      AppStatus.neutral => _BadgeStyle(
        background: scheme.surfaceContainer,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}

class _BadgeStyle {
  const _BadgeStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
