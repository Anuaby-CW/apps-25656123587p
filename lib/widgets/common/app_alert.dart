import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppAlertType { success, error, warning, info }

class AppAlert {
  const AppAlert._();

  static void show(
    BuildContext context,
    String message, {
    AppAlertType type = AppAlertType.info,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = AppSemanticColors.of(context);

    Color bg;
    Color border;
    Color text;
    IconData icon;

    switch (type) {
      case AppAlertType.success:
        bg = semanticColors.successContainer;
        border = semanticColors.success;
        text = semanticColors.onSuccessContainer;
        icon = Icons.check_circle_outline;
        break;
      case AppAlertType.error:
        bg = colorScheme.errorContainer;
        border = colorScheme.error;
        text = colorScheme.onErrorContainer;
        icon = Icons.error_outline;
        break;
      case AppAlertType.warning:
        bg = semanticColors.warningContainer;
        border = semanticColors.warning;
        text = semanticColors.onWarningContainer;
        icon = Icons.warning_amber_outlined;
        break;
      case AppAlertType.info:
        bg = semanticColors.infoContainer;
        border = semanticColors.info;
        text = semanticColors.onInfoContainer;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: AppShadows.surfaceElevation,
        backgroundColor: bg,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.input,
          side: BorderSide(color: border, width: 1.5),
        ),
        content: Semantics(
          container: true,
          liveRegion: true,
          label: message,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(icon, color: text, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTypography.body.copyWith(
                        color: text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
