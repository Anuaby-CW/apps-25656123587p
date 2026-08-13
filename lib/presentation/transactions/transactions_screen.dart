import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/order_models.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

enum _TransactionFilter { activeShift, today, all }

/// Buku struk admin & kasir dengan filter Shift Aktif, Hari Ini, dan Semua Riwayat.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _TransactionFilter _filter = _TransactionFilter.activeShift;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final shiftVal = ref.watch(shiftControllerProvider);
    final shift = shiftVal.value;

    return AppPageFrame(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'PANTAU',
            title: 'Transaksi',
            description:
                'Telusuri setiap struk lunas dan rincian pembayarannya.',
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_TransactionFilter>(
                segments: const [
                  ButtonSegment(
                    value: _TransactionFilter.activeShift,
                    icon: Icon(Icons.badge_outlined),
                    label: Text('Shift Aktif'),
                  ),
                  ButtonSegment(
                    value: _TransactionFilter.today,
                    icon: Icon(Icons.today_outlined),
                    label: Text('Hari Ini'),
                  ),
                  ButtonSegment(
                    value: _TransactionFilter.all,
                    icon: Icon(Icons.history_outlined),
                    label: Text('Semua Riwayat'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) =>
                    setState(() => _filter = selection.first),
              ),
            ),
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          orders.when(
            loading: () =>
                const AppLoadingState(message: 'Menyusun buku transaksi…'),
            error: (error, _) => AppErrorState(
              message: ErrorMessage.from(error),
              onRetry: () => ref.invalidate(ordersProvider),
            ),
            data: (rows) {
              final paid = rows
                  .where(
                    (order) => order.paymentStatus == PaymentStatus.paid.name,
                  )
                  .toList();

              final filteredPaid = paid.where((order) {
                switch (_filter) {
                  case _TransactionFilter.activeShift:
                    if (shift == null || !shift.isActive || shift.startTime == null) {
                      return false;
                    }
                    return order.createdAt.isAfter(shift.startTime!) ||
                        order.createdAt.isAtSameMomentAs(shift.startTime!);
                  case _TransactionFilter.today:
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    return order.createdAt.isAfter(todayStart) ||
                        order.createdAt.isAtSameMomentAs(todayStart);
                  case _TransactionFilter.all:
                    return true;
                }
              }).toList();

              if (filteredPaid.isEmpty) {
                final String emptyTitle;
                final String emptyMessage;
                if (_filter == _TransactionFilter.activeShift) {
                  if (shift == null || !shift.isActive) {
                    emptyTitle = 'Shift Belum Dibuka';
                    emptyMessage =
                        'Buka shift kasir terlebih dahulu untuk mencatat transaksi.';
                  } else {
                    emptyTitle = 'Belum Ada Transaksi di Shift Ini';
                    emptyMessage =
                        'Transaksi yang diproses selama shift aktif ini akan tampil di sini.';
                  }
                } else if (_filter == _TransactionFilter.today) {
                  emptyTitle = 'Belum Ada Transaksi Hari Ini';
                  emptyMessage =
                      'Struk pembayaran lunas hari ini akan tersusun di sini.';
                } else {
                  emptyTitle = 'Belum Ada Transaksi Lunas';
                  emptyMessage =
                      'Riwayat seluruh struk lunas akan tersusun di sini.';
                }

                return AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: emptyTitle,
                  message: emptyMessage,
                );
              }
              return _TransactionBook(rows: filteredPaid, ref: ref);
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionBook extends StatelessWidget {
  const _TransactionBook({required this.rows, required this.ref});

  final List<OrderRecord> rows;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final ledgerIsSafe =
            constraints.maxWidth >= AppLayout.expandedBreakpoint &&
            textScale <= 1.3;
        if (ledgerIsSafe) {
          return _AdminSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TransactionLedgerHeader(),
                const Divider(height: AppSpacing.xxs),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  itemBuilder: (context, index) =>
                      _TransactionLedgerRow(order: rows[index], ref: ref),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) =>
              _TransactionSlipCard(order: rows[index], ref: ref),
        );
      },
    );
  }
}

class _TransactionLedgerHeader extends StatelessWidget {
  const _TransactionLedgerHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSecondaryContainer,
      fontWeight: FontWeight.w700,
    );
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppLayout.adminPrimaryControlHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: AppRadius.input,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TRANSAKSI', style: headerStyle)),
          Expanded(flex: 2, child: Text('PELANGGAN', style: headerStyle)),
          Expanded(flex: 2, child: Text('WAKTU', style: headerStyle)),
          Expanded(
            child: Text(
              'STATUS',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          Expanded(
            child: Text('TOTAL', textAlign: TextAlign.end, style: headerStyle),
          ),
          const SizedBox(width: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _TransactionLedgerRow extends StatelessWidget {
  const _TransactionLedgerRow({required this.order, required this.ref});

  final OrderRecord order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderDetail?>(
      future: ref.read(ordersRepositoryProvider).detail(order.id),
      builder: (context, snapshot) {
        final colors = Theme.of(context).colorScheme;
        final detail = snapshot.data;
        final transactionNumber =
            detail?.transaction?.transactionNumber ?? order.orderNumber;
        return InkWell(
          borderRadius: AppRadius.input,
          onTap: detail == null
              ? null
              : () => _showTransactionDetail(context, detail),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.hero),
            child: Container(
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
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transactionNumber,
                          style: AppTypography.bodyStrong,
                        ),
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      order.customerName ?? 'Tanpa nama',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormatter.human(order.createdAt),
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: AppStatusBadge(
                        label: 'Lunas',
                        status: AppStatus.success,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      MoneyFormatter.format(order.total),
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyStrong.merge(
                        AppTypography.monetary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppSpacing.section,
                    height: AppSpacing.section,
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: SizedBox.square(
                              dimension: AppSpacing.lg,
                              child: CircularProgressIndicator(
                                strokeWidth: AppLayout.progressStrokeWidth,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.chevron_right,
                            color: colors.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionSlipCard extends StatelessWidget {
  const _TransactionSlipCard({required this.order, required this.ref});

  final OrderRecord order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderDetail?>(
      future: ref.read(ordersRepositoryProvider).detail(order.id),
      builder: (context, snapshot) {
        final colors = Theme.of(context).colorScheme;
        final detail = snapshot.data;
        return _AdminSurfaceCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: AppRadius.card,
            onTap: detail == null
                ? null
                : () => _showTransactionDetail(context, detail),
            child: Padding(
              padding: AppSpacing.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail?.transaction?.transactionNumber ??
                                  order.orderNumber,
                              style: AppTypography.title,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              order.orderNumber,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const AppStatusBadge(
                        label: 'Lunas',
                        status: AppStatus.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SlipMetadata(
                    icon: Icons.person_outline,
                    value: order.customerName ?? 'Tanpa nama',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SlipMetadata(
                    icon: Icons.schedule_outlined,
                    value: DateFormatter.human(order.createdAt),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: [
                      Text('Total', style: AppTypography.caption),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          MoneyFormatter.format(order.total),
                          textAlign: TextAlign.end,
                          style: AppTypography.title.merge(
                            AppTypography.monetary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox.square(
                          dimension: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppLayout.progressStrokeWidth,
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlipMetadata extends StatelessWidget {
  const _SlipMetadata({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

Future<void> _showTransactionDetail(BuildContext context, OrderDetail detail) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final compact = AppLayout.isCompact(
        MediaQuery.sizeOf(dialogContext).width,
      );
      if (compact) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  detail.transaction?.transactionNumber ??
                      detail.order.orderNumber,
                ),
                leading: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              body: AppPageFrame(
                child: _TransactionDetailContent(detail: detail),
              ),
            ),
          ),
        );
      }
      return AlertDialog(
        title: Text(
          detail.transaction?.transactionNumber ?? detail.order.orderNumber,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.dialogLargeMaxWidth,
          ),
          child: SingleChildScrollView(
            child: _TransactionDetailContent(detail: detail),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

class _TransactionDetailContent extends StatelessWidget {
  const _TransactionDetailContent({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final order = detail.order;
    return LayoutBuilder(
      builder: (context, constraints) {
        final summary = _OrderSummary(detail: detail);
        final items = _OrderItemLedger(detail: detail);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth >= AppLayout.compactBreakpoint &&
            textScale <= 1.3) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: summary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: items),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order.orderNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            summary,
            const SizedBox(height: AppSpacing.lg),
            items,
          ],
        );
      },
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final order = detail.order;
    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ringkasan struk', style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          _DetailLine(label: 'Pesanan', value: order.orderNumber),
          _DetailLine(
            label: 'Pelanggan',
            value: order.customerName ?? 'Tanpa nama',
          ),
          _DetailLine(
            label: 'Kasir',
            value: detail.cashier?.cashierName ?? 'Tidak tersedia',
          ),
          _DetailLine(label: 'Nomor HP', value: order.customerPhone ?? '—'),
          _DetailLine(label: 'Meja', value: order.tableNumber ?? '—'),
          _DetailLine(
            label: 'Tipe',
            value: order.orderType == 'takeAway'
                ? 'Dibawa pulang'
                : 'Makan di tempat',
          ),
          _DetailLine(
            label: 'Waktu',
            value: DateFormatter.human(order.createdAt),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(value, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }
}

class _OrderItemLedger extends StatelessWidget {
  const _OrderItemLedger({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Rincian pembayaran', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        for (final item in detail.items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productNameSnapshot,
                        style: AppTypography.bodyStrong,
                      ),
                      Text(
                        '${item.quantity} × '
                        '${MoneyFormatter.format(item.unitPrice)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  MoneyFormatter.format(item.subtotal),
                  textAlign: TextAlign.end,
                  style: AppTypography.bodyStrong.merge(AppTypography.monetary),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _PaymentTotalLine(
          label: 'Total',
          value: detail.order.total,
          emphasized: true,
        ),
        _PaymentTotalLine(
          label: 'Bayar',
          value: detail.payment?.amountPaid ?? 0,
        ),
        _PaymentTotalLine(
          label: 'Kembali',
          value: detail.payment?.changeAmount ?? 0,
        ),
      ],
    );
  }
}

class _PaymentTotalLine extends StatelessWidget {
  const _PaymentTotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? AppTypography.title : AppTypography.bodyStrong;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: style),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              MoneyFormatter.format(value),
              textAlign: TextAlign.end,
              style: style.merge(AppTypography.monetary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSurfaceCard extends StatelessWidget {
  const _AdminSurfaceCard({
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
