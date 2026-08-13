import 'package:flutter/material.dart';

import '../../theme/app_layout.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Header halaman dengan hierarki eyebrow, judul, deskripsi, dan satu aksi utama.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.action,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textContent = _HeaderText(
          title: title,
          eyebrow: eyebrow,
          description: description,
          availableWidth: constraints.maxWidth,
        );

        if (action == null) {
          return textContent;
        }

        if (constraints.maxWidth < AppLayout.compactBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textContent,
              const SizedBox(height: AppSpacing.md),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textContent),
            const SizedBox(width: AppSpacing.xl),
            action!,
          ],
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.availableWidth,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsiveTextTheme = AppTypography.textThemeForWidth(availableWidth);
    final children = <Widget>[];

    if (eyebrow case final eyebrow?) {
      children.add(
        Text(
          eyebrow,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.xs));
    }

    children.add(
      Semantics(
        header: true,
        child: Text(
          title,
          style: responsiveTextTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    if (description case final description?) {
      children.add(const SizedBox(height: AppSpacing.xs));
      children.add(
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
