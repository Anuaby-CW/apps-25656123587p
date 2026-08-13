import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/printer/cash_drawer_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/idr_amount_input_formatter.dart';
import '../../core/printer/printer_service.dart';
import '../../data/database/app_database.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../providers/app_providers.dart';
import '../../widgets/common/app_alert.dart';

void showTutupShiftDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const TutupShiftDialog(),
  );
}

class BukaShiftOverlay extends ConsumerStatefulWidget {
  const BukaShiftOverlay({super.key});

  @override
  ConsumerState<BukaShiftOverlay> createState() => _BukaShiftOverlayState();
}

class _BukaShiftOverlayState extends ConsumerState<BukaShiftOverlay> {
  final _formKey = GlobalKey<FormState>();
  final _cashierNameController = TextEditingController();
  final _openingCashController = TextEditingController();
  bool _cashierNameInitialized = false;
  bool _opening = false;

  @override
  void dispose() {
    _cashierNameController.dispose();
    _openingCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value?.user;
    if (!_cashierNameInitialized && user != null) {
      _cashierNameController.text = user.cashierName;
      _cashierNameInitialized = true;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: AppSpacing.allLg,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - (AppSpacing.lg * 2))
                      .clamp(0.0, double.infinity)
                      .toDouble(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.dialogSmallMaxWidth,
                    ),
                    child: Card(
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.sheet,
                      ),
                      child: Padding(
                        padding: AppSpacing.allXl,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.lock_open_outlined,
                                size: AppLayout.cashierSecondaryControlHeight,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Buka Shift Baru',
                                style: textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _cashierNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Kasir',
                                  hintText: 'Nama yang tampil pada struk',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Nama kasir wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _openingCashController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Modal Awal (Tunai)',
                                  prefixText: 'Rp ',
                                ),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: const [
                                  IdrAmountInputFormatter(),
                                ],
                                validator: (value) {
                                  if (IdrAmountInputFormatter.parse(
                                        value ?? '',
                                      ) ==
                                      null) {
                                    return 'Modal awal wajib diisi';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _openShift(user),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                liveRegion: _opening,
                                label: _opening
                                    ? 'Shift sedang dibuka'
                                    : 'Mulai shift',
                                child: FilledButton.icon(
                                  onPressed: _opening
                                      ? null
                                      : () => _openShift(user),
                                  icon: SizedBox.square(
                                    dimension: AppSpacing.xl,
                                    child: Center(
                                      child: _opening
                                          ? SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: AppLayout
                                                    .progressStrokeWidth,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : const Icon(Icons.key),
                                    ),
                                  ),
                                  label: const Text('Mulai Shift'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Future<void> _openShift(UserRecord? user) async {
    if (_opening || !_formKey.currentState!.validate()) {
      return;
    }
    if (user == null) {
      AppAlert.show(
        context,
        'Sesi kasir tidak tersedia',
        type: AppAlertType.error,
      );
      return;
    }

    final openingCash = IdrAmountInputFormatter.parse(
      _openingCashController.text,
    )!;
    final cashierName = _cashierNameController.text.trim();
    final shiftController = ref.read(shiftControllerProvider.notifier);
    final cashDrawer = ref.read(cashDrawerServiceProvider);
    setState(() => _opening = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateCashierName(cashierName);
      ref.invalidate(usersProvider);
      await shiftController.openShift(
        cashierId: user.id,
        cashierName: cashierName,
        openingCash: openingCash,
      );

      final drawerStatus = await cashDrawer.testOpen().timeout(
        const Duration(seconds: 5),
        onTimeout: () => CashDrawerCommandStatus.failed,
      );
      if (mounted) {
        AppAlert.show(
          context,
          'Shift berhasil dibuka!',
          type: AppAlertType.success,
        );
        if (drawerStatus != CashDrawerCommandStatus.commandSent) {
          AppAlert.show(
            context,
            'Shift dibuka, tetapi laci kas tidak berhasil terbuka otomatis.',
            type: AppAlertType.warning,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        AppAlert.show(
          context,
          'Gagal membuka shift: ${ErrorMessage.from(error)}',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }
}

class TutupShiftDialog extends ConsumerStatefulWidget {
  const TutupShiftDialog({super.key});

  @override
  ConsumerState<TutupShiftDialog> createState() => _TutupShiftDialogState();
}

class _TutupShiftDialogState extends ConsumerState<TutupShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actualCashController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftVal = ref.watch(shiftControllerProvider);
    final shift = shiftVal.value;
    if (shift == null || !shift.isActive) {
      return const SizedBox.shrink();
    }

    final cashSalesVal = ref.watch(shiftCashSalesProvider);
    final cashSales = cashSalesVal.value;
    final pettyCashEntriesVal = ref.watch(shiftPettyCashEntriesProvider);
    final pettyCashEntries = pettyCashEntriesVal.value;
    final pettyCash = pettyCashEntries?.fold<int>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final summaryError = cashSalesVal.error ?? pettyCashEntriesVal.error;
    final summaryReady =
        summaryError == null && cashSales != null && pettyCash != null;
    final expectedTotal = summaryReady
        ? shift.openingCash + cashSales - pettyCash
        : null;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        minimum: AppSpacing.allXs,
        child: AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.sizeOf(context).width < AppLayout.compactBreakpoint
                ? AppSpacing.sm
                : AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          title: const Text('Tutup Shift Kasir'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.dialogSmallMaxWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kasir: ${shift.cashierName}',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Mulai shift: ${shift.startTime == null ? "-" : DateFormatter.human(shift.startTime!)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _rowItem('Modal awal', shift.openingCash),
                  if (summaryError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label:
                          'Ringkasan kas gagal dimuat. Shift belum dapat ditutup. ${ErrorMessage.from(summaryError)}',
                      child: ExcludeSemantics(
                        child: Container(
                          padding: AppSpacing.allSm,
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: AppRadius.input,
                            border: Border.all(color: colors.error),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colors.onErrorContainer,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Ringkasan kas gagal dimuat. Shift belum dapat ditutup.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colors.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                ErrorMessage.from(summaryError),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  ref.invalidate(shiftCashSalesProvider);
                                  ref.invalidate(shiftPettyCashEntriesProvider);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Muat Ulang'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (!summaryReady) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label: 'Menghitung penjualan tunai dan kas kecil',
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Menghitung penjualan tunai dan kas kecil…',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xs),
                    _rowItem('Penjualan tunai shift ini', cashSales),
                    const SizedBox(height: AppSpacing.xs),
                    _rowItem('Kas keluar', pettyCash, isNegative: true),
                    const Divider(height: AppSpacing.lg),
                    _rowItem(
                      'Total uang diharapkan',
                      expectedTotal!,
                      isBold: true,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _actualCashController,
                    autofocus: true,
                    enabled: summaryReady,
                    decoration: const InputDecoration(
                      labelText: 'Total Uang Fisik di Laci Kas',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: const [IdrAmountInputFormatter()],
                    validator: (value) {
                      if (IdrAmountInputFormatter.parse(value ?? '') == null) {
                        return 'Total uang fisik wajib diisi';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (expectedTotal != null &&
                      _actualCashController.text.isNotEmpty)
                    _CashDifferenceStatus(
                      difference:
                          (IdrAmountInputFormatter.parse(
                                _actualCashController.text,
                              ) ??
                              0) -
                          expectedTotal,
                    ),
                ],
              ),
            ),
          ),
          actionsOverflowButtonSpacing: AppSpacing.xs,
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            SizedBox(
              height: AppLayout.cashierControlHeight,
              child: Semantics(
                liveRegion: _saving,
                label: _saving
                    ? 'Shift sedang ditutup dan laporan sedang dicetak'
                    : 'Tutup shift dan cetak laporan',
                child: FilledButton.icon(
                  onPressed: _saving || !summaryReady
                      ? null
                      : () => _submit(
                          shift.openingCash + cashSales - pettyCash,
                          cashSales,
                          pettyCash,
                          pettyCashEntries!,
                        ),
                  icon: SizedBox.square(
                    dimension: AppSpacing.xl,
                    child: Center(
                      child: _saving
                          ? SizedBox.square(
                              dimension: AppSpacing.lg,
                              child: CircularProgressIndicator(
                                strokeWidth: AppLayout.progressStrokeWidth,
                                color: colors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.lock_clock_outlined),
                    ),
                  ),
                  label: const Text('Tutup Shift dan Cetak'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(
    String label,
    int value, {
    bool isBold = false,
    bool isNegative = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = (isBold ? textTheme.bodyLarge : textTheme.bodyMedium)
        ?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal);
    final valueStyle = labelStyle?.copyWith(
      fontFeatures: AppTypography.monetary.fontFeatures,
    );
    final formatted = isNegative
        ? '- ${MoneyFormatter.format(value)}'
        : MoneyFormatter.format(value);
    return Semantics(
      container: true,
      label: '$label, $formatted',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Text(label, style: labelStyle)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatted,
                  textAlign: TextAlign.right,
                  style: valueStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    int expectedTotal,
    int cashSales,
    int pettyCash,
    List<PettyCashRecord> pettyCashEntries,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final shift = ref.read(shiftControllerProvider).value;
    if (shift == null || !shift.isActive) {
      return;
    }
    final actualVal = IdrAmountInputFormatter.parse(
      _actualCashController.text,
    )!;
    final diff = actualVal - expectedTotal;
    final shiftController = ref.read(shiftControllerProvider.notifier);
    final printer = ref.read(printerServiceProvider);
    final cashDrawer = ref.read(cashDrawerServiceProvider);

    setState(() => _saving = true);
    try {
      // Persist the close first. Printer and drawer failures must never leave
      // the cashier shift active after reconciliation has been confirmed.
      await shiftController.closeShift();

      final printed = await _printShiftReport(
        printer,
        shift,
        cashSales,
        pettyCash,
        expectedTotal,
        actualVal,
        diff,
      );

      CashDrawerCommandStatus drawerStatus;
      try {
        drawerStatus = await cashDrawer.testOpen().timeout(
          const Duration(seconds: 5),
          onTimeout: () => CashDrawerCommandStatus.failed,
        );
      } on Object {
        drawerStatus = CashDrawerCommandStatus.failed;
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showShiftClosedDialog(
          context,
          shift,
          cashSales,
          pettyCash,
          pettyCashEntries,
          expectedTotal,
          actualVal,
          diff,
          printed: printed,
          drawerOpened: drawerStatus == CashDrawerCommandStatus.commandSent,
        );
      }
    } catch (error) {
      if (mounted) {
        AppAlert.show(
          context,
          'Gagal menutup shift: ${ErrorMessage.from(error)}',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _printShiftReport(
    PrinterService printer,
    ShiftState shift,
    int cashSales,
    int pettyCash,
    int expectedTotal,
    int actualVal,
    int diff,
  ) async {
    try {
      if (printer.status != PrinterConnectionStatus.connected) {
        final settings = await ref.read(printerSettingsProvider.future);
        final address = settings.printerAddress;
        if (address == null || address.isEmpty) {
          return false;
        }
        final connected = await printer.connect(
          PrinterDevice(
            name: settings.printerName ?? 'Printer Termal',
            address: address,
          ),
        );
        if (!connected) {
          return false;
        }
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final List<int> bytes = [
        ...generator.reset(),
        ...generator.text(
          'TALAGA COFFEE',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        ...generator.text(
          'Laporan Tutup Shift',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        ...generator.hr(),
        ...generator.text('Kasir: ${shift.cashierName}'),
        ...generator.text(
          'Mulai: ${shift.startTime?.toLocal().toString().substring(0, 16) ?? "-"}',
        ),
        ...generator.text(
          'Selesai: ${DateTime.now().toLocal().toString().substring(0, 16)}',
        ),
        ...generator.hr(),
        ...generator.row([
          PosColumn(text: 'Modal Awal', width: 6),
          PosColumn(
            text: MoneyFormatter.format(shift.openingCash),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        ...generator.row([
          PosColumn(text: 'Penjualan Tunai', width: 6),
          PosColumn(
            text: MoneyFormatter.format(cashSales),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        ...generator.row([
          PosColumn(text: 'Kas Keluar (Petty)', width: 6),
          PosColumn(
            text: '- ${MoneyFormatter.format(pettyCash)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        ...generator.hr(),
        ...generator.row([
          PosColumn(
            text: 'Diharapkan',
            width: 6,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: MoneyFormatter.format(expectedTotal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
        ...generator.row([
          PosColumn(text: 'Uang Fisik', width: 6),
          PosColumn(
            text: MoneyFormatter.format(actualVal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
        ...generator.hr(),
        ...generator.row([
          PosColumn(
            text: 'Selisih',
            width: 6,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: MoneyFormatter.format(diff),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
        ...generator.feed(3),
        ...generator.cut(),
      ];

      return await PrintBluetoothThermal.writeBytes(
        bytes,
      ).timeout(const Duration(seconds: 5), onTimeout: () => false);
    } on Object {
      return false;
    }
  }
}

class _CashDifferenceStatus extends StatelessWidget {
  const _CashDifferenceStatus({required this.difference});

  final int difference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBalanced = difference == 0;
    final isExcess = difference > 0;
    final background = isBalanced
        ? colors.primaryContainer
        : isExcess
        ? colors.secondaryContainer
        : colors.errorContainer;
    final foreground = isBalanced
        ? colors.onPrimaryContainer
        : isExcess
        ? colors.onSecondaryContainer
        : colors.onErrorContainer;
    final icon = isBalanced
        ? Icons.check_circle_outline
        : isExcess
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;
    final title = isBalanced
        ? 'Kas sesuai'
        : isExcess
        ? 'Kas lebih'
        : 'Kas kurang';
    final amount = isBalanced
        ? MoneyFormatter.format(0)
        : isExcess
        ? '+ ${MoneyFormatter.format(difference)}'
        : '- ${MoneyFormatter.format(difference.abs())}';

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title, $amount',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.input,
            border: Border.all(color: foreground.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: AppSpacing.allSm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    amount,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
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

void _showShiftClosedDialog(
  BuildContext context,
  ShiftState shift,
  int cashSales,
  int pettyCash,
  List<PettyCashRecord> pettyCashEntries,
  int expectedTotal,
  int actualVal,
  int diff, {
  required bool printed,
  required bool drawerOpened,
}) {
  var sharing = false;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final colors = Theme.of(context).colorScheme;
        final feedbackLabel = [
          'Shift berhasil ditutup.',
          printed
              ? 'Laporan berhasil dikirim ke printer.'
              : 'Laporan belum berhasil dicetak.',
          if (!drawerOpened) 'Laci kas tidak berhasil terbuka otomatis.',
        ].join(' ');
        return PopScope(
          canPop: !sharing,
          child: SafeArea(
            minimum: AppSpacing.allXs,
            child: AlertDialog(
              scrollable: true,
              title: const Text('Shift Berhasil Ditutup'),
              content: Semantics(
                container: true,
                liveRegion: true,
                label: feedbackLabel,
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            printed
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            color: printed ? colors.primary : colors.tertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              printed
                                  ? 'Laporan shift berhasil dikirim ke printer.'
                                  : 'Shift tersimpan, tetapi laporan belum berhasil dicetak.',
                            ),
                          ),
                        ],
                      ),
                      if (!drawerOpened) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: colors.tertiary),
                            const SizedBox(width: AppSpacing.xs),
                            const Expanded(
                              child: Text(
                                'Laci kas tidak berhasil terbuka otomatis.',
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Berkas PDF laporan tetap dapat dikirim kepada pemilik outlet.',
                      ),
                    ],
                  ),
                ),
              ),
              actionsOverflowButtonSpacing: AppSpacing.xs,
              actions: [
                TextButton(
                  onPressed: sharing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Selesai'),
                ),
                Semantics(
                  liveRegion: sharing,
                  label: sharing ? 'PDF sedang disiapkan' : 'Kirim PDF',
                  child: FilledButton.icon(
                    onPressed: sharing
                        ? null
                        : () async {
                            setDialogState(() => sharing = true);
                            try {
                              await _generateAndSharePdf(
                                shift,
                                cashSales,
                                pettyCash,
                                pettyCashEntries,
                                expectedTotal,
                                actualVal,
                                diff,
                              );
                            } catch (error) {
                              if (dialogContext.mounted) {
                                AppAlert.show(
                                  dialogContext,
                                  'Gagal membagikan PDF: ${ErrorMessage.from(error)}',
                                  type: AppAlertType.error,
                                );
                              }
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(() => sharing = false);
                              }
                            }
                          },
                    icon: SizedBox.square(
                      dimension: AppSpacing.xl,
                      child: Center(
                        child: sharing
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppLayout.progressStrokeWidth,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.share_outlined),
                      ),
                    ),
                    label: const Text('Kirim PDF'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _generateAndSharePdf(
  ShiftState shift,
  int cashSales,
  int pettyCash,
  List<PettyCashRecord> pettyCashEntries,
  int expectedTotal,
  int actualVal,
  int diff,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a6,
      margin: const pw.EdgeInsets.all(10),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              'TALAGA COFFEE',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Laporan Tutup Shift Kasir',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Text('Kasir: ${shift.cashierName}'),
          pw.Text(
            'Waktu Mulai: ${shift.startTime?.toLocal().toString().substring(0, 16) ?? "-"}',
          ),
          pw.Text(
            'Waktu Selesai: ${DateTime.now().toLocal().toString().substring(0, 16)}',
          ),
          pw.Divider(),
          pw.SizedBox(height: 5),
          _pdfRow('Modal Awal', MoneyFormatter.format(shift.openingCash)),
          _pdfRow('Penjualan Tunai', MoneyFormatter.format(cashSales)),
          _pdfRow(
            'Kas Keluar (Petty)',
            '- ${MoneyFormatter.format(pettyCash)}',
          ),
          if (pettyCashEntries.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Rincian Kas Keluar',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...pettyCashEntries.map(_pdfPettyCashEntry),
          ],
          pw.Divider(),
          _pdfRow(
            'Total Diharapkan',
            MoneyFormatter.format(expectedTotal),
            isBold: true,
          ),
          _pdfRow('Uang Fisik', MoneyFormatter.format(actualVal)),
          pw.Divider(),
          _pdfRow('Selisih', MoneyFormatter.format(diff), isBold: true),
        ];
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File(
    '${output.path}/laporan_shift_'
    '${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(await pdf.save(), flush: true);

  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text:
          'Laporan Tutup Shift Kasir - Talaga Coffee\n'
          'Kasir: ${shift.cashierName}\n'
          'Selisih: ${MoneyFormatter.format(diff)}',
    ),
  );
  if (result.status == ShareResultStatus.unavailable) {
    throw StateError('Fitur berbagi tidak tersedia pada perangkat ini');
  }
}

pw.Widget _pdfPettyCashEntry(PettyCashRecord entry) {
  final time = entry.createdAt.toLocal().toString().substring(11, 16);
  final style = const pw.TextStyle(fontSize: 9);
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(width: 0.3)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 30, child: pw.Text(time, style: style)),
        pw.SizedBox(width: 4),
        pw.Expanded(child: pw.Text(entry.notes, style: style)),
        pw.SizedBox(width: 6),
        pw.Text(MoneyFormatter.format(entry.amount), style: style),
      ],
    ),
  );
}

pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
  final style = pw.TextStyle(
    fontSize: 10,
    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
