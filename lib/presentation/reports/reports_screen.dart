import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/models/report_models.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_state_view.dart';
import '../providers/app_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late ReportRange _range;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _range = ReportRange.today(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportSummaryForRangeProvider(_range));
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'PANTAU',
            title: 'Laporan',
            description:
                'Baca performa outlet per periode dan simpan ringkasannya.',
            action: FilledButton.icon(
              onPressed: _exporting ? null : _exportPdf,
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: AppSpacing.lg,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Ekspor PDF'),
            ),
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Expanded(
            child: report.when(
              loading: () =>
                  const AppLoadingState(message: 'Menyiapkan laporan outlet…'),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () =>
                    ref.invalidate(reportSummaryForRangeProvider(_range)),
              ),
              data: (summary) => _ReportContent(
                range: _range,
                summary: summary,
                onRangeChanged: (range) => setState(() => _range = range),
                onCustomRange: _pickCustomRange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: _range.start,
        end: _range.end.subtract(const Duration(milliseconds: 1)),
      ),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _range = ReportRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        ).add(const Duration(days: 1)),
        label: 'Rentang khusus',
      );
    });
  }

  Future<void> _exportPdf() async {
    final user = ref.read(authControllerProvider).value?.user;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final result = await ref
          .read(reportExportUseCaseProvider)
          .exportPdf(
            _range,
            actorUserId: user?.id,
            actorUsername: user?.username,
          );
      ref.invalidate(auditLogsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'PDF tersimpan di Downloads/Talaga Coffee: ${result.fileName}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.range,
    required this.summary,
    required this.onRangeChanged,
    required this.onCustomRange,
  });

  final ReportRange range;
  final ReportSummary summary;
  final ValueChanged<ReportRange> onRangeChanged;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final sectionGap = AppRoleTokens.of(context).sectionGap;
    final colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _ReportSurfaceCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Periode laporan', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${DateFormatter.human(range.start)} — '
                '${DateFormatter.human(range.end.subtract(const Duration(milliseconds: 1)))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RangeSelector(
                range: range,
                onChanged: onRangeChanged,
                onCustom: onCustomRange,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        Text('Ringkasan periode', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _ReportMetricLedger(summary: summary),
        SizedBox(height: sectionGap),
        _ReportSurfaceCard(
          child: _CategoryLedger(salesByCategory: summary.salesByCategory),
        ),
        SizedBox(height: sectionGap),
      ],
    );
  }
}

class _ReportMetricLedger extends StatelessWidget {
  const _ReportMetricLedger({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricCard(
        'Omzet periode',
        MoneyFormatter.format(summary.totalRevenue),
        Icons.trending_up,
      ),
      _MetricCard(
        'Transaksi lunas',
        summary.paidTransactionCount.toString(),
        Icons.receipt_long,
      ),
      _MetricCard(
        'Tunai diterima',
        MoneyFormatter.format(summary.totalCashReceived),
        Icons.payments,
      ),
      _MetricCard(
        'Produk terlaris',
        summary.bestSellingProduct,
        Icons.star_outline,
      ),
      if (FeatureFlags.cancelledOrdersReport)
        _MetricCard(
          'Pesanan dibatalkan',
          summary.cancelledOrderCount.toString(),
          Icons.cancel_outlined,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.sm;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns =
            constraints.maxWidth >= AppLayout.expandedBreakpoint &&
                textScale <= 1.3
            ? 3
            : !AppLayout.isCompact(constraints.maxWidth) && textScale <= 1.6
            ? 2
            : 1;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics) SizedBox(width: width, child: metric),
          ],
        );
      },
    );
  }
}

class _CategoryLedger extends StatelessWidget {
  const _CategoryLedger({required this.salesByCategory});

  final Map<String, int> salesByCategory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Penjualan per kategori', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Kontribusi omzet dari transaksi yang sudah lunas.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (rows.isEmpty)
          const AppEmptyState(
            icon: Icons.donut_small_outlined,
            title: 'Belum ada penjualan kategori',
            message:
                'Data akan tampil setelah transaksi pada periode ini lunas.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              if (constraints.maxWidth < AppLayout.expandedBreakpoint ||
                  textScale > 1.3) {
                return Column(
                  children: [
                    for (final row in rows)
                      _CategoryCompactRow(name: row.key, revenue: row.value),
                  ],
                );
              }
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: AppRadius.input,
                    ),
                    children: const [
                      _LedgerCell(label: 'KATEGORI', header: true),
                      _LedgerCell(label: 'OMZET', header: true, alignEnd: true),
                    ],
                  ),
                  for (final row in rows)
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      children: [
                        _LedgerCell(label: row.key),
                        _LedgerCell(
                          label: MoneyFormatter.format(row.value),
                          alignEnd: true,
                          strong: true,
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _CategoryCompactRow extends StatelessWidget {
  const _CategoryCompactRow({required this.name, required this.revenue});

  final String name;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppLayout.adminPrimaryControlHeight,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.sell_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(name, style: AppTypography.bodyStrong)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              MoneyFormatter.format(revenue),
              textAlign: TextAlign.end,
              style: AppTypography.bodyStrong.merge(AppTypography.monetary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerCell extends StatelessWidget {
  const _LedgerCell({
    required this.label,
    this.header = false,
    this.alignEnd = false,
    this.strong = false,
  });

  final String label;
  final bool header;
  final bool alignEnd;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: header
            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              )
            : strong
            ? AppTypography.bodyStrong.merge(AppTypography.monetary)
            : AppTypography.body,
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.range,
    required this.onChanged,
    required this.onCustom,
  });

  final ReportRange range;
  final ValueChanged<ReportRange> onChanged;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: const Text('Hari ini'),
          selected: range.label == 'Hari ini',
          onSelected: (_) => onChanged(ReportRange.today(now)),
        ),
        ChoiceChip(
          label: const Text('Kemarin'),
          selected: range.label == 'Kemarin',
          onSelected: (_) => onChanged(ReportRange.yesterday(now)),
        ),
        ChoiceChip(
          label: const Text('7 hari'),
          selected: range.label == '7 hari',
          onSelected: (_) => onChanged(ReportRange.last7Days(now)),
        ),
        ActionChip(
          avatar: const Icon(Icons.date_range),
          label: const Text('Rentang khusus'),
          onPressed: onCustom,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ReportSurfaceCard(
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
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: AppTypography.title.merge(AppTypography.monetary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSurfaceCard extends StatelessWidget {
  const _ReportSurfaceCard({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = highlighted ? colors.secondaryContainer : colors.surface;
    final foreground = highlighted
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final localTheme = theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      iconTheme: theme.iconTheme.copyWith(color: foreground),
    );

    return Theme(
      data: localTheme,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(padding: AppSpacing.allLg, child: child),
      ),
    );
  }
}
