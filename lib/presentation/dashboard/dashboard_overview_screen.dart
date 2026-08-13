import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/routing/app_destination.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/models/report_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_chart_tokens.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

enum _ChartMetric { revenue, transactions }

enum _ChartView { distribution, trend }

enum _RankingMode { highest, lowest }

bool _allowsHorizontalDashboardLayout(
  BuildContext context,
  double availableWidth,
  double minimumWidth,
) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  final compactHeight = AppLayout.isCompactHeight(
    MediaQuery.sizeOf(context).height,
  );
  return !compactHeight && availableWidth >= minimumWidth && textScale <= 1.3;
}

Color _dashboardChartColor(BuildContext context, int index) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkChartColorAt(index)
      : AppColors.chartColorAt(index);
}

Color _chartLabelColor(BuildContext context, Color background) {
  final scheme = Theme.of(context).colorScheme;
  final surfaceContrast = _contrastRatio(background, scheme.surface);
  final onSurfaceContrast = _contrastRatio(background, scheme.onSurface);
  return surfaceContrast >= onSurfaceContrast
      ? scheme.surface
      : scheme.onSurface;
}

double _contrastRatio(Color first, Color second) {
  final lighter = math.max(first.computeLuminance(), second.computeLuminance());
  final darker = math.min(first.computeLuminance(), second.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

/// Admin landing page. All analytics are composed from ReportsRepository data.
class DashboardOverviewScreen extends ConsumerStatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  ConsumerState<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState
    extends ConsumerState<DashboardOverviewScreen> {
  late ReportRange _range;
  _ChartView _chartView = _ChartView.distribution;
  _ChartMetric _metric = _ChartMetric.revenue;
  _RankingMode _rankingMode = _RankingMode.highest;
  RevenueComparisonPeriod _comparisonPeriod = RevenueComparisonPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _range = ReportRange.today(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(dashboardAnalyticsProvider(_range));
    final comparison = ref.watch(revenueComparisonProvider(_comparisonPeriod));
    return AppPageFrame(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'PANTAU',
            title: 'Dashboard',
            description:
                'Ringkasan performa dan perhatian operasional Talaga Coffee.',
            action: FilledButton.icon(
              onPressed: _openReports,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka laporan detail'),
            ),
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          analytics.when(
            loading: () =>
                const AppLoadingState(message: 'Menyiapkan meja pantau…'),
            error: (error, _) => AppErrorState(
              message: ErrorMessage.from(error),
              onRetry: () =>
                  ref.invalidate(dashboardAnalyticsProvider(_range)),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardAnalyticsProvider(_range));
                ref.invalidate(revenueComparisonProvider(_comparisonPeriod));
                ref.invalidate(adminCatalogSnapshotProvider);
                await ref.read(dashboardAnalyticsProvider(_range).future);
              },
              child: _DashboardWorkbench(
                data: data,
                comparison: comparison,
                comparisonPeriod: _comparisonPeriod,
                onComparisonPeriodChanged: (period) =>
                    setState(() => _comparisonPeriod = period),
                range: _range,
                onRangeChanged: (range) => setState(() => _range = range),
                onCustomRange: _pickCustomRange,
                chartView: _chartView,
                onChartViewChanged: (view) =>
                    setState(() => _chartView = view),
                chartMetric: _metric,
                onChartMetricChanged: (metric) =>
                    setState(() => _metric = metric),
                rankingMode: _rankingMode,
                onRankingModeChanged: (mode) =>
                    setState(() => _rankingMode = mode),
                onOpenInventory: _openInventory,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReports() {
    ref
        .read(selectedDestinationProvider.notifier)
        .select(AppDestination.reports);
  }

  void _openInventory() {
    ref
        .read(selectedDestinationProvider.notifier)
        .select(AppDestination.inventory);
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
    if (picked == null || !mounted) {
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
}

class _DashboardWorkbench extends StatelessWidget {
  const _DashboardWorkbench({
    required this.data,
    required this.comparison,
    required this.comparisonPeriod,
    required this.onComparisonPeriodChanged,
    required this.range,
    required this.onRangeChanged,
    required this.onCustomRange,
    required this.chartView,
    required this.onChartViewChanged,
    required this.chartMetric,
    required this.onChartMetricChanged,
    required this.rankingMode,
    required this.onRankingModeChanged,
    required this.onOpenInventory,
  });

  final DashboardAnalytics data;
  final AsyncValue<RevenueComparison> comparison;
  final RevenueComparisonPeriod comparisonPeriod;
  final ValueChanged<RevenueComparisonPeriod> onComparisonPeriodChanged;
  final ReportRange range;
  final ValueChanged<ReportRange> onRangeChanged;
  final VoidCallback onCustomRange;
  final _ChartView chartView;
  final ValueChanged<_ChartView> onChartViewChanged;
  final _ChartMetric chartMetric;
  final ValueChanged<_ChartMetric> onChartMetricChanged;
  final _RankingMode rankingMode;
  final ValueChanged<_RankingMode> onRankingModeChanged;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    final sectionGap = AppRoleTokens.of(context).sectionGap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitSummary = _allowsHorizontalDashboardLayout(
          context,
          constraints.maxWidth,
          AppLayout.expandedBreakpoint,
        );
        final splitWorkbench = _allowsHorizontalDashboardLayout(
          context,
          constraints.maxWidth,
          AppLayout.largeBreakpoint,
        );
        final attention = _LowStockAlert(onOpenInventory: onOpenInventory);
        final summary = _QuickSummary(data: data);
        final chart = _SalesChartCard(
          data: data,
          view: chartView,
          onViewChanged: onChartViewChanged,
          metric: chartMetric,
          onMetricChanged: onChartMetricChanged,
        );
        final ranking = _ProductRankingCard(
          quantities: data.rangeSummary.productQuantities,
          mode: rankingMode,
          onModeChanged: onRankingModeChanged,
        );

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (splitSummary)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: summary),
                  SizedBox(width: sectionGap),
                  Expanded(flex: 4, child: attention),
                ],
              )
            else ...[
              attention,
              SizedBox(height: sectionGap),
              summary,
            ],
            SizedBox(height: sectionGap),
            _RevenueComparisonCard(
              value: comparison,
              period: comparisonPeriod,
              onPeriodChanged: onComparisonPeriodChanged,
            ),
            SizedBox(height: sectionGap),
            AppSectionCard(
              tone: AppSectionTone.lake,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periode analitik', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${DateFormatter.human(range.start)} — '
                    '${DateFormatter.human(range.end.subtract(const Duration(milliseconds: 1)))}',
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            if (splitWorkbench)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: chart),
                  SizedBox(width: sectionGap),
                  Expanded(flex: 4, child: ranking),
                ],
              )
            else ...[
              chart,
              SizedBox(height: sectionGap),
              ranking,
            ],
            SizedBox(height: sectionGap),
            _CategorySummaryCard(
              salesByCategory: data.rangeSummary.salesByCategory,
            ),
            SizedBox(height: sectionGap),
          ],
        );
      },
    );
  }
}

class _LowStockAlert extends ConsumerWidget {
  const _LowStockAlert({required this.onOpenInventory});

  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    return catalog.when(
      loading: () => const AppSectionCard(
        tone: AppSectionTone.neutral,
        child: AppLoadingState(message: 'Memeriksa stok minimum…'),
      ),
      error: (error, _) => AppSectionCard(
        tone: AppSectionTone.attention,
        child: AppErrorState(
          title: 'Status stok belum terbaca',
          message: ErrorMessage.from(error),
          onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
        ),
      ),
      data: (snapshot) {
        final rows = snapshot.lowStockInventory;
        if (rows.isEmpty) {
          return const AppSectionCard(
            tone: AppSectionTone.lake,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppStatusBadge(
                  label: 'Stok terkendali',
                  status: AppStatus.success,
                  icon: Icons.check_circle_outline,
                ),
                SizedBox(height: AppSpacing.sm),
                Text('Tidak ada produk yang mencapai batas minimum.'),
              ],
            ),
          );
        }
        final productById = {
          for (final product in snapshot.products) product.id: product,
        };
        return AppSectionCard(
          tone: AppSectionTone.attention,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStatusBadge(
                label: 'Perlu perhatian',
                status: AppStatus.danger,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${rows.length} produk mencapai batas stok minimum',
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final row in rows.take(5))
                    Chip(
                      avatar: const Icon(Icons.inventory_2_outlined),
                      label: Text(
                        '${productById[row.productId]?.name ?? row.productId}: '
                        '${row.quantity}/${row.lowStockThreshold}',
                      ),
                    ),
                  if (rows.length > 5)
                    Chip(label: Text('+${rows.length - 5} lainnya')),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: onOpenInventory,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Buka Stok'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueComparisonCard extends StatelessWidget {
  const _RevenueComparisonCard({
    required this.value,
    required this.period,
    required this.onPeriodChanged,
  });

  final AsyncValue<RevenueComparison> value;
  final RevenueComparisonPeriod period;
  final ValueChanged<RevenueComparisonPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    return AppSectionCard(
      tone: AppSectionTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perbandingan omzet', style: AppTypography.title),
                  Text(
                    'Periode terakhir dibanding periode sebelumnya',
                    style: AppTypography.caption
                        .merge(AppTypography.monetary)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SegmentedButton<RevenueComparisonPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: RevenueComparisonPeriod.weekly,
                      label: Text('Mingguan'),
                    ),
                    ButtonSegment(
                      value: RevenueComparisonPeriod.monthly,
                      label: Text('Bulanan'),
                    ),
                  ],
                  selected: {period},
                  onSelectionChanged: (selection) =>
                      onPeriodChanged(selection.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          value.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                Text('Perbandingan gagal dimuat: ${ErrorMessage.from(error)}'),
            data: (comparison) {
              final change = comparison.revenueChangePercent;
              final isUp = change > 0;
              final isDown = change < 0;
              final color = isUp
                  ? semantic.success
                  : isDown
                  ? scheme.error
                  : scheme.onSurfaceVariant;
              final current = comparison.currentSummary;
              final previous = comparison.previousSummary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = _allowsHorizontalDashboardLayout(
                        context,
                        constraints.maxWidth,
                        AppLayout.compactBreakpoint,
                      );
                      final cards = [
                        _ComparisonValue(
                          label: '${period.days} hari terakhir',
                          revenue: current.totalRevenue,
                          transactions: current.paidTransactionCount,
                        ),
                        _ComparisonValue(
                          label: '${period.days} hari sebelumnya',
                          revenue: previous.totalRevenue,
                          transactions: previous.paidTransactionCount,
                        ),
                      ];
                      return wide
                          ? Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: cards[1]),
                              ],
                            )
                          : Column(
                              children: [
                                cards[0],
                                const SizedBox(height: AppSpacing.sm),
                                cards[1],
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up
                            : isDown
                            ? Icons.trending_down
                            : Icons.trending_flat,
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% '
                          'dibanding periode sebelumnya',
                          style: AppTypography.bodyStrong
                              .merge(AppTypography.monetary)
                              .copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComparisonValue extends StatelessWidget {
  const _ComparisonValue({
    required this.label,
    required this.revenue,
    required this.transactions,
  });

  final String label;
  final int revenue;
  final int transactions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.input,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              MoneyFormatter.format(revenue),
              style: AppTypography.titleLarge
                  .merge(AppTypography.monetary)
                  .copyWith(color: scheme.onSurface),
            ),
            Text(
              '$transactions transaksi lunas',
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary({required this.data});

  final DashboardAnalytics data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final today = data.todaySummary;
    final yesterdayRevenue = data.yesterdaySummary.totalRevenue;
    final change = yesterdayRevenue == 0
        ? (today.totalRevenue == 0 ? 0.0 : 100.0)
        : ((today.totalRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
    final isUp = change > 0;
    final isDown = change < 0;
    final comparisonColor = isUp
        ? semantic.success
        : isDown
        ? scheme.error
        : scheme.onSurfaceVariant;

    final cards = [
      _SummaryCard(
        title: 'Omzet hari ini',
        value: MoneyFormatter.format(today.totalRevenue),
        icon: Icons.payments_outlined,
      ),
      _SummaryCard(
        title: 'Transaksi hari ini',
        value: '${today.paidTransactionCount} transaksi',
        icon: Icons.receipt_long_outlined,
      ),
      _SummaryCard(
        title: 'Dibanding kemarin',
        value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
        detail: MoneyFormatter.format(yesterdayRevenue),
        icon: isUp
            ? Icons.trending_up
            : isDown
            ? Icons.trending_down
            : Icons.trending_flat,
        accent: comparisonColor,
      ),
    ];
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hari ini di Talaga', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final columns =
                  constraints.maxWidth >= AppLayout.expandedBreakpoint &&
                      textScale <= 1.3
                  ? 3
                  : constraints.maxWidth >= AppLayout.compactBreakpoint &&
                        textScale <= 1.6
                  ? 2
                  : 1;
              final gap = AppSpacing.sm;
              final width =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in cards) SizedBox(width: width, child: card),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.detail,
    this.accent,
  });

  final String title;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.input,
        border: Border.fromBorderSide(BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: AppRadius.input,
              ),
              child: Padding(
                padding: AppSpacing.allSm,
                child: Icon(icon, color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption
                        .merge(AppTypography.monetary)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    value,
                    style: AppTypography.title
                        .merge(AppTypography.monetary)
                        .copyWith(color: accent ?? scheme.onSurface),
                  ),
                  if (detail != null)
                    Text(
                      'Kemarin: $detail',
                      style: AppTypography.caption
                          .merge(AppTypography.monetary)
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
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
          label: const Text('Harian'),
          selected: range.label == 'Hari ini',
          onSelected: (_) => onChanged(ReportRange.today(now)),
        ),
        ChoiceChip(
          label: const Text('Mingguan'),
          selected: range.label == '7 hari',
          onSelected: (_) => onChanged(ReportRange.last7Days(now)),
        ),
        ChoiceChip(
          avatar: const Icon(Icons.date_range_outlined),
          label: const Text('Rentang khusus'),
          selected: range.label == 'Rentang khusus',
          onSelected: (_) => onCustom(),
        ),
      ],
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({
    required this.data,
    required this.view,
    required this.onViewChanged,
    required this.metric,
    required this.onMetricChanged,
  });

  final DashboardAnalytics data;
  final _ChartView view;
  final ValueChanged<_ChartView> onViewChanged;
  final _ChartMetric metric;
  final ValueChanged<_ChartMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final showingDistribution = view == _ChartView.distribution;
    final scheme = Theme.of(context).colorScheme;

    return AppSectionCard(
      tone: AppSectionTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showingDistribution
                        ? 'Distribusi omzet per kategori'
                        : 'Tren penjualan',
                    style: AppTypography.title,
                  ),
                  Text(
                    showingDistribution || metric == _ChartMetric.revenue
                        ? 'Total: ${MoneyFormatter.format(data.rangeSummary.totalRevenue)}'
                        : 'Total: ${data.rangeSummary.paidTransactionCount} transaksi',
                    style: AppTypography.caption
                        .merge(AppTypography.monetary)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SegmentedButton<_ChartView>(
                  segments: const [
                    ButtonSegment(
                      value: _ChartView.distribution,
                      label: Text('Distribusi'),
                      icon: Icon(Icons.pie_chart_outline),
                    ),
                    ButtonSegment(
                      value: _ChartView.trend,
                      label: Text('Tren'),
                      icon: Icon(Icons.show_chart),
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (value) => onViewChanged(value.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showingDistribution)
            _CategoryRevenuePieChart(
              salesByCategory: data.rangeSummary.salesByCategory,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: SegmentedButton<_ChartMetric>(
                      segments: const [
                        ButtonSegment(
                          value: _ChartMetric.revenue,
                          label: Text('Omzet'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        ButtonSegment(
                          value: _ChartMetric.transactions,
                          label: Text('Transaksi'),
                          icon: Icon(Icons.receipt_long_outlined),
                        ),
                      ],
                      selected: {metric},
                      onSelectionChanged: (value) =>
                          onMetricChanged(value.first),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SalesTrendChart(data: data, metric: metric),
              ],
            ),
        ],
      ),
    );
  }
}

/// Diagram bawaan Dashboard; nilainya langsung memakai ringkasan Reports.
class _CategoryRevenuePieChart extends StatefulWidget {
  const _CategoryRevenuePieChart({required this.salesByCategory});

  final Map<String, int> salesByCategory;

  @override
  State<_CategoryRevenuePieChart> createState() =>
      _CategoryRevenuePieChartState();
}

class _CategoryRevenuePieChartState extends State<_CategoryRevenuePieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant _CategoryRevenuePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.salesByCategory, widget.salesByCategory)) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows =
        widget.salesByCategory.entries.where((row) => row.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Belum ada distribusi omzet',
        message: 'Kategori akan tampil setelah transaksi periode ini lunas.',
      );
    }

    final total = rows.fold<int>(0, (sum, row) => sum + row.value);
    final selectedIndex = _touchedIndex >= 0 && _touchedIndex < rows.length
        ? _touchedIndex
        : -1;
    final selected = selectedIndex == -1 ? null : rows[selectedIndex];
    final semantic = AppSemanticColors.of(context);
    Color colorForIndex(int index) => _dashboardChartColor(context, index);
    final chartSummary = rows
        .map(
          (row) =>
              '${row.key}, ${MoneyFormatter.format(row.value)}, '
              '${_percentage(row.value, total)}',
        )
        .join('; ');

    final chart = Semantics(
      container: true,
      image: true,
      label:
          'Diagram distribusi omzet kategori. '
          'Total ${MoneyFormatter.format(total)}. $chartSummary',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.adminPieChartSize,
            maxHeight: AppLayout.adminPieChartSize,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dimension = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final geometryScale =
                  dimension /
                  (2 *
                      (AppChartTokens.pieCenterRadius +
                          AppChartTokens.pieSelectedRadius));
              final showInlineLabels =
                  dimension >= 260 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              return SizedBox.square(
                dimension: dimension,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: AppChartTokens.pieSectionSpace,
                    centerSpaceRadius:
                        AppChartTokens.pieCenterRadius * geometryScale,
                    pieTouchData: PieTouchData(
                      touchCallback: (_, response) {
                        final index =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
                        if (index >= 0 &&
                            index < rows.length &&
                            index != _touchedIndex) {
                          setState(() => _touchedIndex = index);
                        }
                      },
                    ),
                    sections: [
                      for (var index = 0; index < rows.length; index++)
                        _section(
                          color: colorForIndex(index),
                          labelColor: _chartLabelColor(
                            context,
                            colorForIndex(index),
                          ),
                          value: rows[index].value,
                          total: total,
                          selected: index == selectedIndex,
                          normalRadius:
                              AppChartTokens.pieRadius * geometryScale,
                          selectedRadius:
                              AppChartTokens.pieSelectedRadius * geometryScale,
                          showInlineLabel: showInlineLabels,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final legend = _PieLegend(
      rows: rows,
      total: total,
      selectedIndex: selectedIndex,
      colorForIndex: colorForIndex,
      onSelected: (index) => setState(() => _touchedIndex = index),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (_allowsHorizontalDashboardLayout(
              context,
              constraints.maxWidth,
              AppLayout.compactBreakpoint,
            )) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  chart,
                  const SizedBox(width: AppSpacing.adminWide),
                  Expanded(child: legend),
                ],
              );
            }
            return Column(
              children: [
                chart,
                const SizedBox(height: AppSpacing.md),
                legend,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedContainer(
          duration: AppMotion.standard,
          padding: AppSpacing.allMd,
          decoration: BoxDecoration(
            color: semantic.infoContainer,
            borderRadius: AppRadius.input,
          ),
          child: selected == null
              ? Row(
                  children: [
                    Icon(Icons.touch_app_outlined, color: semantic.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Ketuk bagian diagram untuk melihat rincian omzet.',
                        style: TextStyle(color: semantic.onInfoContainer),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: AppSpacing.sm,
                      height: AppSpacing.section,
                      decoration: BoxDecoration(
                        color: colorForIndex(selectedIndex),
                        borderRadius: AppRadius.badge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.key,
                            style: AppTypography.bodyStrong.copyWith(
                              color: semantic.onInfoContainer,
                            ),
                          ),
                          Text(
                            '${_percentage(selected.value, total)} dari omzet kategori',
                            style: AppTypography.caption
                                .merge(AppTypography.monetary)
                                .copyWith(color: semantic.onInfoContainer),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            MoneyFormatter.format(selected.value),
                            style: AppTypography.title
                                .merge(AppTypography.monetary)
                                .copyWith(color: semantic.onInfoContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  PieChartSectionData _section({
    required Color color,
    required Color labelColor,
    required int value,
    required int total,
    required bool selected,
    required double normalRadius,
    required double selectedRadius,
    required bool showInlineLabel,
  }) {
    final percent = value / total * 100;
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      radius: selected ? selectedRadius : normalRadius,
      title: showInlineLabel && (percent >= 5 || selected)
          ? _percentage(value, total)
          : '',
      titlePositionPercentageOffset: AppChartTokens.pieTitlePosition,
      titleStyle: (selected ? AppTypography.label : AppTypography.caption)
          .merge(AppTypography.monetary)
          .copyWith(color: labelColor),
    );
  }

  static String _percentage(int value, int total) {
    final percent = value / total * 100;
    final decimals = percent >= 10 ? 0 : 1;
    return '${percent.toStringAsFixed(decimals)}%';
  }
}

class _PieLegend extends StatelessWidget {
  const _PieLegend({
    required this.rows,
    required this.total,
    required this.selectedIndex,
    required this.colorForIndex,
    required this.onSelected,
  });

  final List<MapEntry<String, int>> rows;
  final int total;
  final int selectedIndex;
  final Color Function(int index) colorForIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: index == selectedIndex
                  ? semantic.infoContainer
                  : scheme.surface.withValues(alpha: 0),
              borderRadius: AppRadius.input,
              child: InkWell(
                borderRadius: AppRadius.input,
                onTap: () => onSelected(index),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: BoxDecoration(
                            color: colorForIndex(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      rows[index].key,
                                      style: AppTypography.bodyStrong,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    _CategoryRevenuePieChartState._percentage(
                                      rows[index].value,
                                      total,
                                    ),
                                    style: AppTypography.label
                                        .merge(AppTypography.monetary)
                                        .copyWith(
                                          color: index == selectedIndex
                                              ? semantic.onInfoContainer
                                              : semantic.info,
                                        ),
                                  ),
                                ],
                              ),
                              Text(
                                MoneyFormatter.format(rows[index].value),
                                style: AppTypography.caption
                                    .merge(AppTypography.monetary)
                                    .copyWith(
                                      color: index == selectedIndex
                                          ? semantic.onInfoContainer
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dipertahankan sebagai tampilan "Tren" agar diagram garis tetap tersedia.
class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.data, required this.metric});

  final DashboardAnalytics data;
  final _ChartMetric metric;

  @override
  Widget build(BuildContext context) {
    final points = data.chartPoints;
    final scheme = Theme.of(context).colorScheme;
    final values = [
      for (final point in points)
        metric == _ChartMetric.revenue
            ? point.summary.totalRevenue.toDouble()
            : point.summary.paidTransactionCount.toDouble(),
    ];
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final color = _dashboardChartColor(context, 0);

    if (maxValue == 0) {
      return const AppEmptyState(
        icon: Icons.show_chart,
        title: 'Belum ada tren penjualan',
        message: 'Grafik akan terbentuk setelah transaksi periode ini lunas.',
      );
    }

    final metricLabel = metric == _ChartMetric.revenue ? 'omzet' : 'transaksi';
    final summary = <String>[
      for (var index = 0; index < points.length; index++)
        '${_pointLabel(points[index])}: '
            '${metric == _ChartMetric.revenue ? MoneyFormatter.format(values[index]) : '${values[index].toInt()} transaksi'}',
    ].join('; ');

    return Semantics(
      container: true,
      image: true,
      label: 'Grafik tren $metricLabel. $summary',
      child: ExcludeSemantics(
        child: SizedBox(
          height: AppLayout.adminTrendChartHeight,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(0, points.length - 1).toDouble(),
              minY: 0,
              maxY: maxValue * 1.2,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.outlineVariant,
                  strokeWidth: AppChartTokens.gridStrokeWidth,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: AppChartTokens.leftAxisReservedSize,
                    getTitlesWidget: (value, meta) => Text(
                      _compactValue(value, metric),
                      style: AppTypography.caption
                          .merge(AppTypography.monetary)
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: AppChartTokens.bottomAxisReservedSize,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final skip = points.length > 8 && index.isOdd;
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          skip ? '' : _pointLabel(points[index]),
                          style: AppTypography.caption
                              .merge(AppTypography.monetary)
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        metric == _ChartMetric.revenue
                            ? MoneyFormatter.format(spot.y)
                            : '${spot.y.toInt()} transaksi',
                        AppTypography.bodyStrong
                            .merge(AppTypography.monetary)
                            .copyWith(color: scheme.onInverseSurface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < values.length; index++)
                      FlSpot(index.toDouble(), values[index]),
                  ],
                  color: color,
                  barWidth: AppChartTokens.lineWidth,
                  isCurved: points.length > 2,
                  dotData: FlDotData(show: points.length <= 14),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _compactValue(double value, _ChartMetric metric) {
    if (metric == _ChartMetric.transactions) {
      return value.round().toString();
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).round()} rb';
    }
    return value.round().toString();
  }

  static String _pointLabel(ReportChartPoint point) {
    if (point.end.difference(point.start).inHours <= 4) {
      return point.label;
    }
    return DateFormat('dd/MM').format(point.start);
  }
}

class _ProductRankingCard extends StatelessWidget {
  const _ProductRankingCard({
    required this.quantities,
    required this.mode,
    required this.onModeChanged,
  });

  final Map<String, int> quantities;
  final _RankingMode mode;
  final ValueChanged<_RankingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final ranking = quantities.entries.toList()
      ..sort(
        (a, b) => mode == _RankingMode.highest
            ? b.value.compareTo(a.value)
            : a.value.compareTo(b.value),
      );
    final visible = ranking.take(5).toList();

    return AppSectionCard(
      tone: AppSectionTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Ranking produk', style: AppTypography.title),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SegmentedButton<_RankingMode>(
                  segments: const [
                    ButtonSegment(
                      value: _RankingMode.highest,
                      label: Text('Terlaris'),
                    ),
                    ButtonSegment(
                      value: _RankingMode.lowest,
                      label: Text('Terendah'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (value) => onModeChanged(value.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Text(
              'Belum ada produk terjual pada periode ini.',
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < visible.length; index++)
              ListTile(
                contentPadding: AppSpacing.zero,
                leading: DecoratedBox(
                  decoration: BoxDecoration(
                    color: semantic.infoContainer,
                    borderRadius: AppRadius.badge,
                  ),
                  child: Padding(
                    padding: AppSpacing.allXs,
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.label.copyWith(
                        color: semantic.onInfoContainer,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  visible[index].key,
                  style: AppTypography.bodyStrong,
                ),
                trailing: Text(
                  '${visible[index].value} produk',
                  style: AppTypography.bodyStrong.merge(AppTypography.monetary),
                ),
              ),
        ],
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  const _CategorySummaryCard({required this.salesByCategory});

  final Map<String, int> salesByCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final rows = salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return AppSectionCard(
      tone: AppSectionTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Omzet per kategori', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Lima kategori dengan kontribusi omzet terbesar.',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text(
              'Belum ada data kategori pada periode ini.',
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final row in rows.take(5))
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sell_outlined, color: semantic.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(row.key, style: AppTypography.bodyStrong),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        MoneyFormatter.format(row.value),
                        textAlign: TextAlign.end,
                        style: AppTypography.bodyStrong.merge(
                          AppTypography.monetary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
