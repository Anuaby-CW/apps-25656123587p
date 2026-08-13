import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../data/database/app_database.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_state_view.dart';
import '../providers/app_providers.dart';

class AuditTrailScreen extends ConsumerWidget {
  const AuditTrailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogsProvider);
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'OPERASIONAL',
            title: 'Jurnal Aktivitas',
            description:
                'Jejak perubahan data, stok, printer, dan laporan outlet.',
            action: SizedBox.square(
              dimension: AppSpacing.section,
              child: IconButton.filledTonal(
                tooltip: 'Segarkan riwayat aktivitas',
                onPressed: () => ref.invalidate(auditLogsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Expanded(
            child: logs.when(
              loading: () => const AppLoadingState(
                message: 'Menyiapkan jurnal aktivitas…',
              ),
              error: (error, _) => AppErrorState(
                title: 'Jurnal aktivitas belum terbaca',
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(auditLogsProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const AppEmptyState(
                    title: 'Riwayat aktivitas kosong',
                    message:
                        'Perubahan produk, stok, printer, dan ekspor akan tampil di sini.',
                    icon: Icons.manage_search,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    if (constraints.maxWidth >= AppLayout.expandedBreakpoint &&
                        textScale <= 1.3) {
                      return _AuditLedger(rows: rows);
                    }
                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final colors = Theme.of(context).colorScheme;
                        final row = rows[index];
                        final entity = _auditEntityLabel(row.entityType);
                        return _AuditSurfaceCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: AppRadius.input,
                                ),
                                child: Padding(
                                  padding: AppSpacing.allSm,
                                  child: Icon(
                                    _entityIcon(row.entityType),
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _auditDescription(row.description),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xxs,
                                      children: [
                                        Text(_auditActionLabel(row.action)),
                                        Text('• $entity'),
                                        if (row.actorUsername != null)
                                          Text('• ${row.actorUsername}'),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      DateFormatter.human(row.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLedger extends StatelessWidget {
  const _AuditLedger({required this.rows});

  final List<AuditLogRecord> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: colors.onSecondaryContainer,
      fontWeight: FontWeight.w700,
    );

    return _AuditSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(
              minHeight: AppLayout.adminPrimaryControlHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(color: colors.secondaryContainer),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('WAKTU', style: headerStyle)),
                Expanded(flex: 4, child: Text('AKTIVITAS', style: headerStyle)),
                Expanded(flex: 2, child: Text('TINDAKAN', style: headerStyle)),
                Expanded(flex: 2, child: Text('ENTITAS', style: headerStyle)),
                Expanded(flex: 2, child: Text('AKTOR', style: headerStyle)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return Container(
                  constraints: const BoxConstraints(minHeight: AppSpacing.hero),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormatter.human(row.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Icon(
                              _entityIcon(row.entityType),
                              color: colors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _auditDescription(row.description),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_auditActionLabel(row.action)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_auditEntityLabel(row.entityType)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(row.actorUsername ?? 'Sistem'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditSurfaceCard extends StatelessWidget {
  const _AuditSurfaceCard({
    required this.child,
    this.padding = AppSpacing.allLg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

IconData _entityIcon(String entityType) => switch (entityType) {
  'product' => Icons.local_cafe_outlined,
  'inventory' => Icons.inventory_2_outlined,
  'printer' => Icons.print_outlined,
  'report' => Icons.summarize_outlined,
  'user' => Icons.person_outline,
  _ => Icons.history,
};

String _auditActionLabel(String action) => switch (action) {
  'product.create' => 'Produk dibuat',
  'product.update' => 'Produk diperbarui',
  'product.activate' => 'Produk diaktifkan',
  'product.deactivate' => 'Produk dinonaktifkan',
  'inventory.adjust' => 'Stok disesuaikan',
  'inventory.threshold.update' => 'Batas minimum stok diubah',
  'printer.connect' => 'Printer dihubungkan',
  'printer.disconnect' => 'Printer diputuskan',
  'printer.test_print' => 'Cetak uji printer',
  'printer.cash_drawer_test' => 'Uji laci kas',
  'report.export' => 'Laporan diekspor',
  'user.create' => 'Pengguna dibuat',
  'user.update' => 'Pengguna diperbarui',
  'admin.reset_data' => 'Data outlet direset',
  _ => action,
};

String _auditEntityLabel(String entityType) => switch (entityType) {
  'product' => 'Produk',
  'inventory' => 'Stok',
  'printer' => 'Printer',
  'report' => 'Laporan',
  'user' => 'Pengguna',
  'database' => 'Database',
  _ => entityType,
};

String _auditDescription(String description) {
  final patterns = <(RegExp, String Function(RegExpMatch))>[
    (RegExp(r'^Created product (.+)$'), (match) => 'Produk ${match[1]} dibuat'),
    (
      RegExp(r'^Updated product (.+)$'),
      (match) => 'Produk ${match[1]} diperbarui',
    ),
    (
      RegExp(r'^Activated product (.+)$'),
      (match) => 'Produk ${match[1]} diaktifkan',
    ),
    (
      RegExp(r'^Deactivated product (.+)$'),
      (match) => 'Produk ${match[1]} dinonaktifkan',
    ),
    (
      RegExp(r'^Connected printer (.+)$'),
      (match) => 'Printer ${match[1]} berhasil dihubungkan',
    ),
    (
      RegExp(r'^Failed to connect printer (.+)$'),
      (match) => 'Gagal menghubungkan printer ${match[1]}',
    ),
    (
      RegExp(r'^Disconnected printer (.+)$'),
      (match) => 'Printer ${match[1]} diputuskan',
    ),
  ];
  for (final (pattern, replacement) in patterns) {
    final match = pattern.firstMatch(description);
    if (match != null) {
      return replacement(match);
    }
  }
  return switch (description) {
    'Test print success' => 'Cetak uji berhasil',
    'Test print failed' => 'Cetak uji gagal',
    _ => description,
  };
}
