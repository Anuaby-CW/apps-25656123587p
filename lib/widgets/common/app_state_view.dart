import 'package:flutter/material.dart';

import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_section_card.dart';

/// State loading stabil yang tidak mengubah dimensi area aksi di sekitarnya.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message = 'Memuat data…',
    this.placeholder,
  });

  final String message;

  /// Placeholder opsional, misalnya skeleton ledger admin.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: AppSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: AppLayout.progressStrokeWidth,
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.dialogSmallMaxWidth,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (placeholder case final placeholder?) ...[
                const SizedBox(height: AppSpacing.xl),
                placeholder,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// State error dengan instruksi natural dan aksi retry opsional.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Data belum dapat dimuat',
    this.message = 'Silakan coba lagi.',
    this.onRetry,
    this.retryLabel = 'Coba lagi',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _AppStateBody(
      icon: Icons.error_outline,
      iconBackground: scheme.error,
      iconForeground: scheme.onError,
      title: title,
      message: message,
      tone: AppSectionTone.attention,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
    );
  }
}

/// State kosong yang menjelaskan konteks dan dapat menawarkan satu aksi pemulihan.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Belum ada data',
    this.message = 'Data akan tampil di sini saat tersedia.',
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null && onAction == null) ||
             (actionLabel != null && onAction != null),
         'actionLabel dan onAction harus diisi bersamaan.',
       );

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.of(context);
    return _AppStateBody(
      icon: icon,
      iconBackground: semanticColors.infoContainer,
      iconForeground: semanticColors.onInfoContainer,
      title: title,
      message: message,
      tone: AppSectionTone.plain,
      action: onAction == null
          ? null
          : FilledButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}

class _AppStateBody extends StatelessWidget {
  const _AppStateBody({
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.title,
    required this.message,
    required this.tone,
    required this.action,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String message;
  final AppSectionTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      liveRegion: tone == AppSectionTone.attention,
      child: AppSectionCard(
        tone: tone,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: AppRadius.chip,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: iconForeground),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.dialogSmallMaxWidth,
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action case final action?) ...[
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
