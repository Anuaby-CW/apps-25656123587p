import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/utils/idr_amount_input_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/checkout_models.dart';
import '../../domain/models/cart_models.dart';
import '../../domain/models/enums.dart';
import '../providers/app_providers.dart';
import '../widgets/quick_cash_input.dart';
import '../../widgets/common/app_alert.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key, required this.user});

  final UserRecord user;

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  final _customerName = TextEditingController();
  final _tableNumber = TextEditingController();
  final _amountPaid = TextEditingController();
  final _printCopiesController = TextEditingController(text: '1');
  OrderType _orderType = OrderType.dineIn;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;
  bool _printing = false;
  String? _customerNameError;
  String? _tableNumberError;
  CheckoutResult? _checkoutResult;

  @override
  void dispose() {
    _customerName.dispose();
    _tableNumber.dispose();
    _amountPaid.dispose();
    _printCopiesController.dispose();
    super.dispose();
  }

  int? _parseAmount() {
    return IdrAmountInputFormatter.parse(_amountPaid.text);
  }

  bool _validateCustomerDetails() {
    final customerMissing = _customerName.text.trim().isEmpty;
    final tableMissing =
        FeatureFlags.tableNumber &&
        _orderType == OrderType.dineIn &&
        _tableNumber.text.trim().isEmpty;
    if (!customerMissing && !tableMissing) return true;
    setState(() {
      _customerNameError = customerMissing
          ? 'Nama pelanggan wajib diisi'
          : null;
      _tableNumberError = tableMissing ? 'Nomor meja wajib diisi' : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lengkapi detail pelanggan sebelum menyimpan pesanan.'),
      ),
    );
    return false;
  }

  Future<void> _submit({required bool payNow}) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = ref.read(cartControllerProvider);

    if (!_validateCustomerDetails()) return;
    if (payNow && _paymentMethod == PaymentMethod.qris) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pembayaran QRIS belum tersedia.')),
      );
      return;
    }

    final amountPaid = payNow ? _parseAmount() : null;
    if (payNow && (amountPaid == null || amountPaid < cart.total)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nominal pembayaran tunai tidak valid atau kurang.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final shift = ref.read(shiftControllerProvider).value;
      final cashierName =
          UserRole.fromDb(widget.user.role) == UserRole.cashier &&
              shift?.cashierId == widget.user.id
          ? shift?.cashierName ?? widget.user.cashierName
          : widget.user.cashierName;
      final result = await ref.read(checkoutUseCaseProvider)(
        CheckoutRequest(
          cashierUserId: widget.user.id,
          cashierName: cashierName,
          items: cart.items,
          orderType: _orderType,
          payNow: payNow,
          customerName: _customerName.text.trim(),
          customerPhone: '', // Removed phone field
          tableNumber:
              FeatureFlags.tableNumber && _orderType == OrderType.dineIn
              ? _tableNumber.text.trim()
              : null,
          amountPaid: amountPaid,
        ),
      );

      _invalidateTransactionViews();

      if (mounted) {
        setState(() {
          _checkoutResult = result;
          _submitting = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
      }
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    }
  }

  Future<void> _printCopies(int count) async {
    final result = _checkoutResult;
    if (result == null) return;
    if (count < 1 || count > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah struk harus antara 1 dan 10.')),
      );
      return;
    }
    setState(() => _printing = true);
    try {
      final shift = ref.read(shiftControllerProvider).value;
      final cashierName =
          UserRole.fromDb(widget.user.role) == UserRole.cashier &&
              shift?.cashierId == widget.user.id
          ? shift?.cashierName ?? widget.user.cashierName
          : '';
      for (var i = 0; i < count; i++) {
        final printed = await ref
            .read(receiptUseCaseProvider)
            .printPaidOrder(result.orderId, cashierName);
        if (!printed) {
          throw StateError('Printer gagal mencetak salinan ke-${i + 1}');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengirim $count perintah cetak ke printer'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencetak: ${ErrorMessage.from(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  void _done() {
    ref.read(cartControllerProvider.notifier).clear();
    Navigator.of(context).pop(_checkoutResult);
  }

  void _invalidateTransactionViews() {
    ref.invalidate(ordersProvider);
    ref.invalidate(catalogSnapshotProvider);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(reportSummaryProvider);
    ref.invalidate(reportSummaryForRangeProvider);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(revenueComparisonProvider);
    ref.invalidate(shiftCashSalesProvider);
    ref.invalidate(printerLogsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final amount = _parseAmount();
    final change = amount == null ? null : amount - cart.total;

    final isSuccessState = _checkoutResult != null;
    final isPaidSuccess = _checkoutResult?.paymentStatus == PaymentStatus.paid;

    return PopScope(
      canPop: !_submitting && !isSuccessState,
      child: _CheckoutDialogFrame(
        title: Text(
          isSuccessState
              ? isPaidSuccess
                    ? 'Transaksi Berhasil'
                    : 'Pesanan Disimpan'
              : 'Selesaikan Transaksi',
        ),
        content: isSuccessState
            ? _buildSuccessContent(change ?? 0)
            : _buildInputContent(cart, change),
        footer: _buildDialogFooter(
          cart: cart,
          amount: amount,
          isSuccessState: isSuccessState,
        ),
      ),
    );
  }

  Widget _buildDialogFooter({
    required CartState cart,
    required int? amount,
    required bool isSuccessState,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWindow =
            MediaQuery.sizeOf(context).width < AppLayout.compactBreakpoint;
        final scaledBody = MediaQuery.textScalerOf(
          context,
        ).scale(AppTypography.body.fontSize ?? 14);
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final stackActions =
            (compactWindow && !keyboardOpen) || scaledBody > 18;

        if (isSuccessState) {
          final doneButton = SizedBox(
            height: AppLayout.cashierControlHeight,
            child: FilledButton.icon(
              onPressed: _printing ? null : _done,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Selesai'),
            ),
          );
          return stackActions
              ? SizedBox(width: double.infinity, child: doneButton)
              : Align(alignment: Alignment.centerRight, child: doneButton);
        }

        final cancelButton = TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        );
        final payLaterButton = FeatureFlags.payLater
            ? OutlinedButton.icon(
                onPressed: _submitting ? null : () => _submit(payNow: false),
                icon: const Icon(Icons.schedule_outlined),
                label: const Text('Bayar Nanti'),
              )
            : null;
        final payButton = SizedBox(
          height: AppLayout.cashierControlHeight,
          child: Semantics(
            liveRegion: _submitting,
            label: _submitting
                ? 'Pembayaran sedang diproses'
                : 'Bayar sekarang',
            child: FilledButton.icon(
              onPressed:
                  (_submitting ||
                      _paymentMethod == PaymentMethod.qris ||
                      (amount == null || amount < cart.total))
                  ? null
                  : () => _submit(payNow: true),
              icon: SizedBox.square(
                dimension: AppSpacing.xl,
                child: Center(
                  child: _submitting
                      ? SizedBox.square(
                          dimension: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppLayout.progressStrokeWidth,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.payments_outlined),
                ),
              ),
              label: const Text('Bayar Sekarang'),
            ),
          ),
        );

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cancelButton,
              if (payLaterButton != null) ...[
                const SizedBox(height: AppSpacing.xs),
                payLaterButton,
              ],
              const SizedBox(height: AppSpacing.xs),
              payButton,
            ],
          );
        }

        return Row(
          children: [
            cancelButton,
            const Spacer(),
            if (payLaterButton != null) ...[
              payLaterButton,
              const SizedBox(width: AppSpacing.sm),
            ],
            payButton,
          ],
        );
      },
    );
  }

  Widget _buildInputContent(CartState cart, int? change) {
    final user = ref.watch(authControllerProvider).value?.user;
    final role = user != null ? UserRole.fromDb(user.role) : UserRole.cashier;
    final isCashier = role == UserRole.cashier;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CheckoutTotalBanner(total: cart.total),
        const SizedBox(height: AppSpacing.md),

        // 1. Tipe Pesanan
        const _CheckoutStepLabel(number: '1', label: 'Tipe Pesanan'),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<OrderType>(
          segments: [
            for (final type in OrderType.values)
              ButtonSegment(
                value: type,
                label: Text(
                  type == OrderType.dineIn
                      ? 'Makan di tempat'
                      : 'Dibawa pulang',
                ),
                icon: Icon(
                  type == OrderType.dineIn ? Icons.deck : Icons.takeout_dining,
                ),
              ),
          ],
          selected: {_orderType},
          onSelectionChanged: (value) => setState(() {
            _orderType = value.first;
            if (_orderType == OrderType.takeAway) {
              _tableNumberError = null;
            }
          }),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Detail Pelanggan (Nama saja)
        const _CheckoutStepLabel(number: '2', label: 'Detail Pelanggan'),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _customerName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nama Pelanggan',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: _customerNameError,
          ),
          onChanged: (_) {
            if (_customerNameError != null) {
              setState(() => _customerNameError = null);
            }
          },
        ),
        if (FeatureFlags.customerNameShortcut && !isCashier) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.bolt_outlined),
              label: const Text('Pelanggan Umum'),
              onPressed: () {
                _customerName.text = 'Pelanggan Umum';
                setState(() => _customerNameError = null);
              },
            ),
          ),
        ],
        if (FeatureFlags.tableNumber && _orderType == OrderType.dineIn) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _tableNumber,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Nomor Meja',
              hintText: 'Contoh: 4 atau A2',
              prefixIcon: const Icon(Icons.table_restaurant_outlined),
              errorText: _tableNumberError,
            ),
            onChanged: (_) {
              if (_tableNumberError != null) {
                setState(() => _tableNumberError = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final table in const ['1', '2', '3', '4', '5', '6'])
                ActionChip(
                  label: Text(table),
                  onPressed: () {
                    _tableNumber.text = table;
                    setState(() => _tableNumberError = null);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // 3. Metode Pembayaran (Tunai / QRIS)
        const _CheckoutStepLabel(number: '3', label: 'Pilih Pembayaran'),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<PaymentMethod>(
          segments: [
            for (final method in PaymentMethod.values)
              ButtonSegment(
                value: method,
                label: Text(method.label),
                icon: Icon(
                  method == PaymentMethod.cash
                      ? Icons.payments_outlined
                      : Icons.qr_code_2_outlined,
                ),
                enabled: method == PaymentMethod.cash,
              ),
          ],
          selected: {_paymentMethod},
          onSelectionChanged: (value) =>
              setState(() => _paymentMethod = value.first),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Detail Pembayaran sesuai Pilihan
        if (_paymentMethod == PaymentMethod.cash) ...[
          const _CheckoutStepLabel(
            number: '4',
            label: 'Nominal Tunai & Akses Cepat',
          ),
          const SizedBox(height: AppSpacing.xs),
          QuickCashInput(
            controller: _amountPaid,
            total: cart.total,
            onChanged: (_) => setState(() {}),
          ),
          if (change != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _PaymentFeedback(
              isShort: change < 0,
              text: change < 0
                  ? 'Nominal pembayaran kurang.'
                  : 'Kembalian ${MoneyFormatter.format(change)}',
            ),
          ],
        ] else ...[
          Builder(
            builder: (context) {
              final colors = Theme.of(context).colorScheme;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  border: Border.all(color: colors.tertiary),
                  borderRadius: AppRadius.card,
                ),
                child: Padding(
                  padding: AppSpacing.allMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.onTertiaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Pembayaran QRIS Segera Hadir',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: colors.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'QRIS belum diaktifkan karena API dan akun merchant belum dikonfigurasi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessContent(int change) {
    final result = _checkoutResult!;
    final isPaid = result.paymentStatus == PaymentStatus.paid;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: isPaid
              ? 'Pembayaran berhasil. Nomor pesanan ${result.orderNumber}.'
              : 'Pesanan berhasil disimpan. Nomor pesanan ${result.orderNumber}.',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: colors.primary, size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isPaid ? 'Pembayaran Berhasil' : 'Pesanan Berhasil Disimpan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nomor Pesanan: ${result.orderNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!isPaid)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              border: Border.all(color: colors.tertiary),
              borderRadius: AppRadius.card,
            ),
            child: Padding(
              padding: AppSpacing.allMd,
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: colors.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Status belum lunas. Terima pembayaran dari menu Pesanan.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              border: Border.all(color: colors.primary),
              borderRadius: AppRadius.card,
            ),
            child: Padding(
              padding: AppSpacing.allMd,
              child: Column(
                children: [
                  Text(
                    'KEMBALIAN',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    MoneyFormatter.format(change),
                    style: AppTypography.display.copyWith(
                      color: colors.onPrimaryContainer,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (result.cashDrawerAttempted && !result.cashDrawerOpened) ...[
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.errorContainer,
                border: Border.all(color: colors.error),
                borderRadius: AppRadius.card,
              ),
              child: Padding(
                padding: AppSpacing.allMd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.point_of_sale_outlined, color: colors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        result.cashDrawerError ??
                            'Laci kas tidak berhasil terbuka otomatis. Buka laci secara manual dan periksa koneksi printer.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _CheckoutStepLabel(number: '!', label: 'Cetak Struk Tambahan'),
          const SizedBox(height: AppSpacing.xs),
          _PrintCopiesPanel(
            controller: _printCopiesController,
            printing: _printing,
            onPrint: (count) {
              if (count == null) {
                AppAlert.show(
                  context,
                  'Masukkan jumlah struk yang valid.',
                  type: AppAlertType.error,
                );
                return;
              }
              _printCopies(count);
            },
          ),
        ],
      ],
    );
  }
}

class _CheckoutDialogFrame extends StatelessWidget {
  const _CheckoutDialogFrame({
    required this.title,
    required this.content,
    required this.footer,
  });

  final Widget title;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      minimum: AppSpacing.allSm,
      child: AnimatedPadding(
        duration: AppMotion.standard,
        curve: AppMotion.curve,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : AppLayout.dialogLargeMaxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.dialogMediumMaxWidth,
                  maxHeight: maxHeight,
                ),
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  child: Material(
                    color: colors.surface,
                    surfaceTintColor: theme.dialogTheme.surfaceTintColor,
                    elevation:
                        theme.dialogTheme.elevation ??
                        AppLayout.cashierSecondaryControlHeight / 5,
                    shadowColor: theme.dialogTheme.shadowColor,
                    shape:
                        theme.dialogTheme.shape ??
                        const RoundedRectangleBorder(
                          borderRadius: AppRadius.dialog,
                        ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: DefaultTextStyle(
                            style:
                                theme.dialogTheme.titleTextStyle ??
                                theme.textTheme.titleLarge!,
                            child: Semantics(header: true, child: title),
                          ),
                        ),
                        Divider(height: 1, color: colors.outlineVariant),
                        Flexible(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: AppSpacing.allLg,
                            child: DefaultTextStyle(
                              style:
                                  theme.dialogTheme.contentTextStyle ??
                                  theme.textTheme.bodyMedium!,
                              child: content,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: colors.outlineVariant),
                        ColoredBox(
                          color: colors.surfaceContainerLow,
                          child: Padding(
                            padding: AppSpacing.allMd,
                            child: footer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrintCopiesPanel extends StatelessWidget {
  const _PrintCopiesPanel({
    required this.controller,
    required this.printing,
    required this.onPrint,
  });

  final TextEditingController controller;
  final bool printing;
  final ValueChanged<int?> onPrint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: AppSpacing.zero,
      elevation: 0,
      child: Padding(
        padding: AppSpacing.allMd,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaledBody = MediaQuery.textScalerOf(
              context,
            ).scale(AppTypography.body.fontSize ?? 14);
            final stackControls = constraints.maxWidth < 340 || scaledBody > 18;
            final printButton = Semantics(
              liveRegion: printing,
              label: printing ? 'Struk sedang dicetak' : 'Cetak struk',
              child: FilledButton.icon(
                onPressed: printing
                    ? null
                    : () => onPrint(int.tryParse(controller.text.trim())),
                icon: SizedBox.square(
                  dimension: AppSpacing.xl,
                  child: Center(
                    child: printing
                        ? SizedBox.square(
                            dimension: AppSpacing.lg,
                            child: CircularProgressIndicator(
                              strokeWidth: AppLayout.progressStrokeWidth,
                              color: colors.onSurfaceVariant,
                            ),
                          )
                        : const Icon(Icons.print_outlined),
                  ),
                ),
                label: const Text('Cetak'),
              ),
            );
            final copiesField = TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah struk'),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stackControls) ...[
                  copiesField,
                  const SizedBox(height: AppSpacing.sm),
                  printButton,
                ] else
                  Row(
                    children: [
                      Expanded(child: copiesField),
                      const SizedBox(width: AppSpacing.sm),
                      printButton,
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Pilihan cepat cetak struk',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (stackControls) ...[
                  OutlinedButton(
                    onPressed: printing ? null : () => onPrint(2),
                    child: const Text('Cetak 2 struk'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton(
                    onPressed: printing ? null : () => onPrint(3),
                    child: const Text('Cetak 3 struk'),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: printing ? null : () => onPrint(2),
                          child: const Text('Cetak 2 struk'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: printing ? null : () => onPrint(3),
                          child: const Text('Cetak 3 struk'),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CheckoutTotalBanner extends StatelessWidget {
  const _CheckoutTotalBanner({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        border: Border.all(color: colors.primary),
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_checkout,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BELANJA',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    MoneyFormatter.format(total),
                    style: AppTypography.display.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
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

class _CheckoutStepLabel extends StatelessWidget {
  const _CheckoutStepLabel({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.sm,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(number, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _PaymentFeedback extends StatelessWidget {
  const _PaymentFeedback({required this.isShort, required this.text});

  final bool isShort;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isShort
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isShort
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Semantics(
      container: true,
      liveRegion: true,
      label: text,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.input,
          ),
          child: Padding(
            padding: AppSpacing.allSm,
            child: Row(
              children: [
                Icon(
                  isShort ? Icons.error_outline : Icons.check_circle_outline,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
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
