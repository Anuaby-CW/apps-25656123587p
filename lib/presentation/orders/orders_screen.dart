import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/idr_amount_input_formatter.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/checkout_models.dart';
import '../../domain/models/enums.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_alert.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';
import '../widgets/quick_cash_input.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeader(
            eyebrow: 'OPERASIONAL KASIR',
            title: 'Antrean Pesanan',
            description:
                'Pantau pembayaran dan kesiapan setiap pesanan dari satu layar.',
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Semantics(
            container: true,
            label: 'Filter status pesanan',
            child: SizedBox(
              height: AppLayout.cashierControlHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final filter in [
                    'all',
                    'unpaid',
                    'paid',
                    'preparing',
                    'ready',
                    'completed',
                    'cancelled',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppLayout.cashierSecondaryControlHeight,
                        ),
                        child: ChoiceChip(
                          label: Text(_filterLabel(filter)),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: orders.when(
              loading: () => const AppLoadingState(
                message: 'Menyiapkan antrean pesanan\u2026',
              ),
              error: (error, _) => AppErrorState(
                title: 'Antrean pesanan belum dapat dimuat',
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(ordersProvider),
              ),
              data: (rows) {
                final filtered = rows.where(_matchesFilter).toList();
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Tidak ada pesanan pada status ini',
                    message:
                        'Pesanan baru akan tampil di antrean secara otomatis.',
                  );
                }
                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: filtered[index], role: widget.role),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(OrderRecord order) {
    if (_filter == 'all') {
      return order.orderStatus != OrderStatus.completed.name &&
          order.orderStatus != OrderStatus.cancelled.name;
    }
    if (_filter == 'unpaid') {
      return order.paymentStatus == PaymentStatus.unpaid.name &&
          order.orderStatus != OrderStatus.completed.name &&
          order.orderStatus != OrderStatus.cancelled.name;
    }
    return order.paymentStatus == _filter || order.orderStatus == _filter;
  }

  String _filterLabel(String value) => switch (value) {
    'all' => 'AKTIF',
    'unpaid' => 'BELUM LUNAS',
    'paid' => 'LUNAS',
    'preparing' => 'DISIAPKAN',
    'ready' => 'SIAP',
    'completed' => 'SELESAI',
    'cancelled' => 'DIBATALKAN',
    _ => value.toUpperCase(),
  };
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.role});

  final OrderRecord order;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semanticColors = AppSemanticColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useExpandedLayout =
            constraints.maxWidth >= AppLayout.expandedBreakpoint &&
            textScale <= 1.3;
        final actions = _TicketActions(
          primary: _primaryAction(context, ref),
          onDetail: () => _showDetail(context, ref),
          onPrint: order.paymentStatus == PaymentStatus.paid.name
              ? () => _printReceipt(context, ref)
              : null,
          overflowItems: _overflowItems(ref),
          onOverflowSelected: (action) => _handleOverflow(action, context, ref),
        );

        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: Card(
            margin: AppSpacing.zero,
            elevation: 0,
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _statusStripeColor(colors, semanticColors),
                    ),
                    child: const SizedBox(width: AppSpacing.xs),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.allMd,
                      child: useExpandedLayout
                          ? _buildExpandedContent(context, actions)
                          : _buildCompactContent(context, actions),
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

  Widget _buildCompactContent(BuildContext context, Widget actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdentity(context),
        const SizedBox(height: AppSpacing.sm),
        _buildMoneyAndTime(context),
        const SizedBox(height: AppSpacing.md),
        actions,
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, Widget actions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildIdentity(context)),
        const SizedBox(width: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
          child: _buildMoneyAndTime(
            context,
            alignment: CrossAxisAlignment.end,
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 5, child: actions),
      ],
    );
  }

  Widget _buildIdentity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                order.orderNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _paymentBadge(order.paymentStatus),
            _orderBadge(order.orderStatus),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _TicketFact(
              icon: Icons.person_outline,
              label: order.customerName ?? 'Tanpa nama',
            ),
            if (order.tableNumber case final table?)
              _TicketFact(
                icon: Icons.table_restaurant_outlined,
                label: 'Meja $table',
              ),
            _TicketFact(
              icon: order.orderType == OrderType.takeAway.name
                  ? Icons.shopping_bag_outlined
                  : Icons.restaurant_outlined,
              label: order.orderType == OrderType.takeAway.name
                  ? 'Dibawa pulang'
                  : 'Makan di tempat',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoneyAndTime(
    BuildContext context, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
    TextAlign textAlign = TextAlign.start,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          MoneyFormatter.format(order.total),
          textAlign: textAlign,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontFeatures: AppTypography.monetary.fontFeatures,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          DateFormatter.human(order.createdAt),
          textAlign: textAlign,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: AppTypography.monetary.fontFeatures,
          ),
        ),
      ],
    );
  }

  Widget _paymentBadge(String status) {
    return AppStatusBadge(
      label: PaymentStatus.fromDb(status).label.toUpperCase(),
      status: status == PaymentStatus.paid.name
          ? AppStatus.success
          : AppStatus.warning,
    );
  }

  Widget _orderBadge(String status) {
    final semanticStatus = switch (status) {
      'ready' => AppStatus.info,
      'completed' => AppStatus.success,
      'cancelled' => AppStatus.danger,
      _ => AppStatus.neutral,
    };
    return AppStatusBadge(
      label: OrderStatus.fromDb(status).label.toUpperCase(),
      status: semanticStatus,
    );
  }

  Color _statusStripeColor(
    ColorScheme colors,
    AppSemanticColors semanticColors,
  ) => switch (order.orderStatus) {
    'ready' => semanticColors.info,
    'completed' => semanticColors.success,
    'cancelled' => colors.error,
    _ when order.paymentStatus == PaymentStatus.unpaid.name =>
      semanticColors.warning,
    _ => colors.primary,
  };

  Widget _primaryAction(BuildContext context, WidgetRef ref) {
    if (order.orderStatus == OrderStatus.completed.name ||
        order.orderStatus == OrderStatus.cancelled.name) {
      return OutlinedButton.icon(
        onPressed: () => _showDetail(context, ref),
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Lihat Detail'),
      );
    }
    if (!_canOperate(ref)) {
      return OutlinedButton.icon(
        onPressed: () => _showDetail(context, ref),
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Lihat Detail'),
      );
    }
    if (order.paymentStatus == PaymentStatus.unpaid.name) {
      if (role != UserRole.cashier) {
        return OutlinedButton.icon(
          onPressed: () => _showDetail(context, ref),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Lihat Detail'),
        );
      }
      final user = ref.watch(authControllerProvider).value?.user;
      final shift = ref.watch(shiftControllerProvider).value;
      final canReceivePayment =
          user != null &&
          shift?.isActive == true &&
          shift?.cashierId == user.id;
      return FilledButton.icon(
        onPressed: canReceivePayment
            ? () => _receivePayment(context, ref)
            : null,
        icon: const Icon(Icons.payments),
        label: Text(
          canReceivePayment ? 'Terima Pembayaran' : 'Buka Shift untuk Bayar',
        ),
      );
    }
    if (order.orderStatus == OrderStatus.preparing.name) {
      return FilledButton.icon(
        onPressed: () => _markReady(context, ref),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Tandai Siap'),
      );
    }
    if (order.orderStatus == OrderStatus.ready.name &&
        order.paymentStatus == PaymentStatus.paid.name) {
      return FilledButton.icon(
        onPressed: () => _complete(context, ref),
        icon: const Icon(Icons.done_all),
        label: const Text('Selesaikan'),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showDetail(context, ref),
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Lihat Detail'),
    );
  }

  List<_OrderOverflowAction> _overflowItems(WidgetRef ref) {
    final items = <_OrderOverflowAction>[];
    if (!_canOperate(ref)) {
      return items;
    }
    if (order.orderStatus == OrderStatus.preparing.name &&
        order.paymentStatus == PaymentStatus.unpaid.name) {
      items.add(_OrderOverflowAction.markReady);
    }
    if (order.paymentStatus == PaymentStatus.unpaid.name &&
        order.orderStatus != OrderStatus.cancelled.name &&
        order.orderStatus != OrderStatus.completed.name) {
      items.add(_OrderOverflowAction.cancel);
    }
    return items;
  }

  bool _canOperate(WidgetRef ref) {
    if (role == UserRole.admin) {
      return true;
    }
    final user = ref.watch(authControllerProvider).value?.user;
    final shift = ref.watch(shiftControllerProvider).value;
    return role == UserRole.admin ||
        (role == UserRole.cashier &&
            user != null &&
            shift?.isActive == true &&
            shift?.cashierId == user.id);
  }

  bool _guardOperation(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider).value?.user;
    final shift = ref.read(shiftControllerProvider).value;
    final canOperateNow =
        role == UserRole.admin ||
        (role == UserRole.cashier &&
            user != null &&
            shift?.isActive == true &&
            shift?.cashierId == user.id);
    if (canOperateNow) {
      return true;
    }
    AppAlert.show(
      context,
      'Hanya kasir pemilik shift aktif atau admin yang dapat mengubah pesanan.',
      type: AppAlertType.error,
    );
    return false;
  }

  void _handleOverflow(
    _OrderOverflowAction action,
    BuildContext context,
    WidgetRef ref,
  ) {
    switch (action) {
      case _OrderOverflowAction.markReady:
        _markReady(context, ref);
        return;
      case _OrderOverflowAction.complete:
        _complete(context, ref);
        return;
      case _OrderOverflowAction.cancel:
        _cancel(context, ref);
        return;
    }
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref) async {
    final detail = await ref.read(ordersRepositoryProvider).detail(order.id);
    if (!context.mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SafeArea(
        minimum: AppSpacing.allSm,
        child: AlertDialog(
          scrollable: true,
          title: Text('Rincian ${order.orderNumber}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.dialogMediumMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < detail.items.length; index++) ...[
                  _OrderDetailItem(
                    name: detail.items[index].productNameSnapshot,
                    description:
                        [
                              detail.items[index].categoryNameSnapshot,
                              detail.items[index].temperatureOption,
                              _sugarLabel(detail.items[index].sugarOption),
                              detail.items[index].manualBrewMethodNameSnapshot,
                              detail.items[index].beanNameSnapshot,
                              detail.items[index].notes,
                            ]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' / '),
                    quantity: detail.items[index].quantity,
                    subtotal: detail.items[index].subtotal,
                  ),
                  if (index != detail.items.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
          actions: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppLayout.cashierSecondaryControlHeight,
              ),
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markReady(BuildContext context, WidgetRef ref) async {
    if (!_guardOperation(context, ref)) return;
    if (order.orderStatus != OrderStatus.preparing.name) return;
    try {
      await ref.read(ordersRepositoryProvider).markReady(order.id);
      if (!context.mounted) return;
      ref.invalidate(ordersProvider);
    } catch (error) {
      if (!context.mounted) return;
      AppAlert.show(
        context,
        ErrorMessage.from(error),
        type: AppAlertType.error,
      );
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    if (!_guardOperation(context, ref)) return;
    if (order.orderStatus != OrderStatus.ready.name ||
        order.paymentStatus != PaymentStatus.paid.name) {
      return;
    }
    try {
      await ref.read(ordersRepositoryProvider).complete(order.id);
      if (!context.mounted) return;
      _invalidateOrderViews(ref);
    } catch (error) {
      if (!context.mounted) return;
      AppAlert.show(
        context,
        ErrorMessage.from(error),
        type: AppAlertType.error,
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    if (!_guardOperation(context, ref)) return;
    if (order.paymentStatus != PaymentStatus.unpaid.name ||
        order.orderStatus == OrderStatus.completed.name ||
        order.orderStatus == OrderStatus.cancelled.name) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SafeArea(
        minimum: AppSpacing.allSm,
        child: AlertDialog(
          scrollable: true,
          icon: Icon(
            Icons.warning_amber_outlined,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Batalkan Pesanan?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.dialogSmallMaxWidth,
            ),
            child: Text(
              'Pesanan ${order.orderNumber} akan ditandai dibatalkan. Tindakan ini tidak dapat dibatalkan.',
            ),
          ),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: _CancelDialogActions(
                onBack: () => Navigator.of(dialogContext).pop(false),
                onCancel: () => Navigator.of(dialogContext).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(ordersRepositoryProvider).cancel(order.id);
      if (!context.mounted) return;
      _invalidateOrderViews(ref);
    } catch (error) {
      if (!context.mounted) return;
      AppAlert.show(
        context,
        ErrorMessage.from(error),
        type: AppAlertType.error,
      );
    }
  }

  Future<void> _receivePayment(BuildContext context, WidgetRef ref) async {
    if (order.paymentStatus != PaymentStatus.unpaid.name ||
        order.orderStatus == OrderStatus.cancelled.name ||
        order.orderStatus == OrderStatus.completed.name) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _ReceivePaymentDialog(order: order),
    );
  }

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).value?.user;
    final shift = ref.read(shiftControllerProvider).value;
    final cashierName =
        user != null &&
            UserRole.fromDb(user.role) == UserRole.cashier &&
            shift?.cashierId == user.id
        ? shift?.cashierName ?? user.cashierName
        : '';
    try {
      final printed = await ref
          .read(receiptUseCaseProvider)
          .printPaidOrder(order.id, cashierName);
      if (!context.mounted) return;
      AppAlert.show(
        context,
        printed ? 'Struk dicetak' : 'Struk gagal dicetak',
        type: printed ? AppAlertType.success : AppAlertType.error,
      );
    } catch (error) {
      if (!context.mounted) return;
      AppAlert.show(
        context,
        ErrorMessage.from(error),
        type: AppAlertType.error,
      );
    }
  }
}

void _invalidateOrderViews(WidgetRef ref) {
  ref.invalidate(ordersProvider);
  ref.invalidate(reportSummaryProvider);
  ref.invalidate(reportSummaryForRangeProvider);
  ref.invalidate(dashboardAnalyticsProvider);
  ref.invalidate(revenueComparisonProvider);
  ref.invalidate(shiftCashSalesProvider);
}

enum _OrderOverflowAction { markReady, complete, cancel }

extension on _OrderOverflowAction {
  String get label => switch (this) {
    _OrderOverflowAction.markReady => 'Tandai siap',
    _OrderOverflowAction.complete => 'Selesaikan',
    _OrderOverflowAction.cancel => 'Batalkan pesanan',
  };

  IconData get icon => switch (this) {
    _OrderOverflowAction.markReady => Icons.check_circle_outline,
    _OrderOverflowAction.complete => Icons.done_all,
    _OrderOverflowAction.cancel => Icons.cancel_outlined,
  };
}

class _OrderDetailItem extends StatelessWidget {
  const _OrderDetailItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final String description;
  final int quantity;
  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountLabel = '$quantity × ${MoneyFormatter.format(subtotal)}';
    return Semantics(
      container: true,
      label: [
        name,
        if (description.isNotEmpty) description,
        amountLabel,
      ].join(', '),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stack = constraints.maxWidth < 420 || textScale > 1.3;
            final descriptionBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            );
            final amount = Text(
              amountLabel,
              textAlign: stack ? TextAlign.start : TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: AppTypography.monetary.fontFeatures,
              ),
            );

            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  descriptionBlock,
                  const SizedBox(height: AppSpacing.sm),
                  amount,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: descriptionBlock),
                const SizedBox(width: AppSpacing.lg),
                amount,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TicketFact extends StatelessWidget {
  const _TicketFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.secondary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketActions extends StatelessWidget {
  const _TicketActions({
    required this.primary,
    required this.onDetail,
    required this.onPrint,
    required this.overflowItems,
    required this.onOverflowSelected,
  });

  final Widget primary;
  final VoidCallback onDetail;
  final VoidCallback? onPrint;
  final List<_OrderOverflowAction> overflowItems;
  final ValueChanged<_OrderOverflowAction> onOverflowSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackAll = constraints.maxWidth < 340 || textScale > 1.6;
        final stackPrimary =
            stackAll || constraints.maxWidth < 520 || textScale > 1.3;
        final primaryAction = ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.cashierControlHeight,
          ),
          child: primary,
        );
        final secondaryActions = _secondaryActions(context);

        if (stackAll) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primaryAction,
              for (final action in secondaryActions) ...[
                const SizedBox(height: AppSpacing.xs),
                action,
              ],
            ],
          );
        }

        if (stackPrimary) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primaryAction,
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: secondaryActions,
              ),
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [primaryAction, ...secondaryActions],
        );
      },
    );
  }

  List<Widget> _secondaryActions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return [
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.cashierSecondaryControlHeight,
        ),
        child: OutlinedButton.icon(
          onPressed: onDetail,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Lihat Detail'),
        ),
      ),
      if (onPrint case final print?)
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.cashierSecondaryControlHeight,
          ),
          child: OutlinedButton.icon(
            onPressed: print,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Cetak Struk'),
          ),
        ),
      if (overflowItems.isNotEmpty)
        SizedBox.square(
          dimension: AppLayout.cashierSecondaryControlHeight,
          child: PopupMenuButton<_OrderOverflowAction>(
            tooltip: 'Aksi pesanan lainnya',
            onSelected: onOverflowSelected,
            itemBuilder: (context) => [
              for (final item in overflowItems)
                PopupMenuItem(
                  value: item,
                  child: ListTile(
                    minTileHeight: AppLayout.cashierSecondaryControlHeight,
                    contentPadding: AppSpacing.zero,
                    leading: Icon(
                      item.icon,
                      color: item == _OrderOverflowAction.cancel
                          ? colors.error
                          : colors.onSurface,
                    ),
                    title: Text(item.label),
                  ),
                ),
            ],
            icon: const Icon(Icons.more_horiz),
          ),
        ),
    ];
  }
}

String? _sugarLabel(String? value) => switch (value) {
  'No Sugar' => 'Tanpa Gula',
  'Less Sugar' => 'Sedikit Gula',
  'Normal Sugar' => 'Normal',
  _ => value,
};

class _CancelDialogActions extends StatelessWidget {
  const _CancelDialogActions({required this.onBack, required this.onCancel});

  final VoidCallback onBack;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = Theme.of(context).colorScheme;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 360 || textScale > 1.3;
        final backButton = ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.cashierSecondaryControlHeight,
          ),
          child: OutlinedButton(
            onPressed: onBack,
            child: const Text('Kembali'),
          ),
        );
        final cancelButton = ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.cashierSecondaryControlHeight,
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batalkan Pesanan'),
          ),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              backButton,
              const SizedBox(height: AppSpacing.sm),
              cancelButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: backButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cancelButton),
          ],
        );
      },
    );
  }
}

class _PaymentTotal extends StatelessWidget {
  const _PaymentTotal({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final formattedTotal = MoneyFormatter.format(total);

    return Semantics(
      container: true,
      label: 'Total tagihan $formattedTotal',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.input,
          ),
          child: Padding(
            padding: AppSpacing.allMd,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stack = constraints.maxWidth < 320 || textScale > 1.3;
                final label = Text(
                  'Total Tagihan',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                );
                final amount = Text(
                  formattedTotal,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontFeatures: AppTypography.monetary.fontFeatures,
                  ),
                );

                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label,
                      const SizedBox(height: AppSpacing.xs),
                      amount,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: label),
                    const SizedBox(width: AppSpacing.md),
                    amount,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentChangeFeedback extends StatelessWidget {
  const _PaymentChangeFeedback({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semanticColors = AppSemanticColors.of(context);
    final isShort = change < 0;
    final message = isShort
        ? 'Nominal pembayaran kurang ${MoneyFormatter.format(-change)}'
        : 'Kembalian ${MoneyFormatter.format(change)}';
    final background = isShort
        ? colors.errorContainer
        : semanticColors.successContainer;
    final foreground = isShort
        ? colors.onErrorContainer
        : semanticColors.onSuccessContainer;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.input,
          ),
          child: Padding(
            padding: AppSpacing.allSm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isShort
                      ? Icons.error_outline
                      : Icons.currency_exchange_outlined,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontFeatures: AppTypography.monetary.fontFeatures,
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
}

class _PaymentDialogActions extends StatelessWidget {
  const _PaymentDialogActions({
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool submitting;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 360 || textScale > 1.3;
        final cancelButton = ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.cashierSecondaryControlHeight,
          ),
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Batal'),
          ),
        );
        final submitButton = Semantics(
          liveRegion: submitting,
          label: submitting
              ? 'Pembayaran sedang diproses'
              : 'Simpan pembayaran',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.cashierControlHeight,
            ),
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: submitting
                      ? CircularProgressIndicator(
                          strokeWidth: AppLayout.progressStrokeWidth,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : const Icon(Icons.payments_outlined),
                ),
              ),
              label: const Text('Simpan Pembayaran'),
            ),
          ),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cancelButton,
              const SizedBox(height: AppSpacing.sm),
              submitButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: submitButton),
          ],
        );
      },
    );
  }
}

class _ReceivePaymentDialog extends ConsumerStatefulWidget {
  const _ReceivePaymentDialog({required this.order});

  final OrderRecord order;

  @override
  ConsumerState<_ReceivePaymentDialog> createState() =>
      _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends ConsumerState<_ReceivePaymentDialog> {
  final _amount = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount();
    final change = amount == null ? null : amount - widget.order.total;
    final canSubmit =
        !_submitting && amount != null && amount >= widget.order.total;

    return PopScope(
      canPop: !_submitting,
      child: SafeArea(
        minimum: AppSpacing.allSm,
        child: AlertDialog(
          scrollable: true,
          title: Text('Terima Pembayaran ${widget.order.orderNumber}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.dialogSmallMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentTotal(total: widget.order.total),
                const SizedBox(height: AppSpacing.md),
                AbsorbPointer(
                  absorbing: _submitting,
                  child: QuickCashInput(
                    controller: _amount,
                    total: widget.order.total,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (change != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _PaymentChangeFeedback(change: change),
                ],
                if (_submitting) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    label: 'Pembayaran sedang diproses',
                    child: const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: _PaymentDialogActions(
                submitting: _submitting,
                onCancel: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
                onSubmit: canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final user = ref.read(authControllerProvider).value?.user;
    if (user == null) {
      return;
    }
    final navigator = Navigator.of(context);
    final role = UserRole.fromDb(user.role);
    var cashierName = user.cashierName;
    if (role == UserRole.cashier) {
      final shift = ref.read(shiftControllerProvider).value;
      if (shift?.isActive != true || shift?.cashierId != user.id) {
        AppAlert.show(
          context,
          'Buka shift kasir ini di menu Pengaturan sebelum menerima pembayaran.',
          type: AppAlertType.error,
        );
        return;
      }
      cashierName = shift?.cashierName ?? user.cashierName;
    }
    final amount = _parseAmount();
    if (amount == null || amount < widget.order.total) {
      AppAlert.show(
        context,
        'Nominal pembayaran masih kurang.',
        type: AppAlertType.error,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref.read(receivePaymentUseCaseProvider)(
        ReceivePaymentRequest(
          orderId: widget.order.id,
          cashierUserId: user.id,
          cashierName: cashierName,
          amountPaid: amount,
        ),
      );
      if (!mounted) return;
      _invalidateOrderViews(ref);
      AppAlert.show(
        context,
        result.printed
            ? 'Pembayaran tersimpan dan struk dicetak'
            : result.printError ?? 'Struk gagal dicetak',
        type: result.printed ? AppAlertType.success : AppAlertType.warning,
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      AppAlert.show(
        context,
        ErrorMessage.from(error),
        type: AppAlertType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  int? _parseAmount() {
    return IdrAmountInputFormatter.parse(_amount.text);
  }
}
