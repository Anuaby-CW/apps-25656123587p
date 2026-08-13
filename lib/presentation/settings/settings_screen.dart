import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feature_flags.dart';
import '../../core/permissions/bluetooth_permission_service.dart';
import '../../core/printer/printer_service.dart';
import '../../core/printer/cash_drawer_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';
import 'widgets/data_management_section.dart';
import '../pos/pos_screen.dart' show showPettyCashDialog;
import '../pos/shift_reconciliation_dialog.dart' show showTutupShiftDialog;
import '../../widgets/common/app_alert.dart';
import '../../core/utils/idr_amount_input_formatter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _outletName = TextEditingController();
  final _outletAddress = TextEditingController();
  final _outletWhatsapp = TextEditingController();
  final _outletInstagram = TextEditingController();
  final _receiptFooter = TextEditingController();
  bool _loadedSettings = false;
  bool _loadingDevices = false;
  List<PrinterDevice> _devices = [];
  PrinterDevice? _selectedDevice;

  @override
  void dispose() {
    _outletName.dispose();
    _outletAddress.dispose();
    _outletWhatsapp.dispose();
    _outletInstagram.dispose();
    _receiptFooter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role != UserRole.admin && widget.role != UserRole.cashier) {
      return const AppPageFrame(
        child: AppErrorState(
          title: 'Akses ditolak',
          message:
              'Pengaturan outlet hanya dapat dibuka oleh admin atau kasir.',
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    final printerSettings = ref.watch(printerSettingsProvider);
    final status =
        ref.watch(printerStatusProvider).value ??
        PrinterConnectionStatus.disconnected;

    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: widget.role == UserRole.admin ? 'OUTLET' : 'PERANGKAT',
            title: widget.role == UserRole.admin
                ? 'Pengaturan Outlet'
                : 'Pengaturan Kasir',
            description: widget.role == UserRole.admin
                ? 'Kelola identitas outlet dan data lokal.'
                : 'Kelola shift, printer thermal, laci kas, dan riwayat perangkat.',
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Expanded(
            child: settings.when(
              loading: () => const AppLoadingState(
                message: 'Menyiapkan pengaturan outlet…',
              ),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(settingsProvider),
              ),
              data: (values) {
                if (!_loadedSettings) {
                  _outletName.text = values['outlet_name'] ?? '';
                  _outletAddress.text = values['outlet_address'] ?? '';
                  _outletWhatsapp.text = values['outlet_whatsapp'] ?? '';
                  _outletInstagram.text = values['outlet_instagram'] ?? '';
                  _receiptFooter.text = values['receipt_footer'] ?? '';
                  _loadedSettings = true;
                }
                return _buildWorkspace(
                  inventoryEnabled: values['inventory_enabled'] != 'false',
                  printerSettings: printerSettings,
                  status: status,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace({
    required bool inventoryEnabled,
    required AsyncValue<PrinterSettingRecord> printerSettings,
    required PrinterConnectionStatus status,
  }) {
    final sectionGap = AppRoleTokens.of(context).sectionGap;
    final compactHeight = AppLayout.isCompactHeight(
      MediaQuery.sizeOf(context).height,
    );

    if (widget.role == UserRole.admin) {
      final leftColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _outletSection(),
          if (FeatureFlags.inventoryManagementSetting) ...[
            SizedBox(height: sectionGap),
            _inventorySection(inventoryEnabled),
          ],
        ],
      );
      final rightColumn = DataManagementSection(role: widget.role);

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (compactHeight ||
                  constraints.maxWidth < AppLayout.expandedBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leftColumn,
                    SizedBox(height: sectionGap),
                    rightColumn,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftColumn),
                  SizedBox(width: sectionGap),
                  Expanded(child: rightColumn),
                ],
              );
            },
          ),
          SizedBox(height: sectionGap),
        ],
      );
    }

    // Cashier role: printer setup, cash drawer, and logs (no data cleaning)
    final printerContent = printerSettings.when(
      loading: () =>
          const AppLoadingState(message: 'Membaca konfigurasi perangkat…'),
      error: (error, _) => AppErrorState(
        title: 'Konfigurasi perangkat belum terbaca',
        message: ErrorMessage.from(error),
        onRetry: () => ref.invalidate(printerSettingsProvider),
      ),
      data: (printer) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _printerSection(printer, status),
          SizedBox(height: sectionGap),
          _cashDrawerSection(printer, status),
        ],
      ),
    );

    final shiftContent = ref
        .watch(shiftControllerProvider)
        .when(
          loading: () =>
              const AppLoadingState(message: 'Membaca status shift…'),
          error: (error, _) => AppErrorState(
            title: 'Status shift belum terbaca',
            message: ErrorMessage.from(error),
            onRetry: () => ref.invalidate(shiftControllerProvider),
          ),
          data: _shiftSection,
        );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final operationalColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                shiftContent,
                SizedBox(height: sectionGap),
                printerContent,
              ],
            );

            if (compactHeight ||
                constraints.maxWidth < AppLayout.expandedBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  operationalColumn,
                  SizedBox(height: sectionGap),
                  _printerLogSection(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: operationalColumn),
                SizedBox(width: sectionGap),
                Expanded(flex: 2, child: _printerLogSection()),
              ],
            );
          },
        ),
        SizedBox(height: sectionGap),
      ],
    );
  }

  Widget _shiftSection(ShiftState shift) {
    if (!shift.isActive) {
      return const _ControlSection(
        title: 'Manajemen Shift',
        description: 'Buka shift baru untuk memulai transaksi di POS.',
        icon: Icons.lock_open_outlined,
        tone: AppSectionTone.warm,
        children: [BukaShiftInlineForm()],
      );
    }

    return _ControlSection(
      title: 'Manajemen Shift & Kas Kecil',
      description: 'Pantau status shift kerja Anda dan catat pengeluaran.',
      icon: Icons.access_time_outlined,
      tone: AppSectionTone.warm,
      children: [
        ListTile(
          contentPadding: AppSpacing.zero,
          leading: const Icon(Icons.person_outline),
          title: Text('Shift Aktif: ${shift.cashierName}'),
          subtitle: Text(
            'Dimulai sejak: ${DateFormatter.human(shift.startTime ?? DateTime.now())}',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final pettyCashButton = SizedBox(
              height: AppLayout.cashierSecondaryControlHeight,
              child: OutlinedButton.icon(
                onPressed: () => showPettyCashDialog(context, ref),
                icon: const Icon(Icons.outbox_outlined),
                label: const Text('Kas Keluar'),
              ),
            );
            final closeShiftButton = SizedBox(
              height: AppLayout.cashierControlHeight,
              child: FilledButton.icon(
                onPressed: () => showTutupShiftDialog(context, ref),
                icon: const Icon(Icons.lock_clock_outlined),
                label: const Text('Tutup Shift'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            );

            if (constraints.maxWidth < AppLayout.compactBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pettyCashButton,
                  const SizedBox(height: AppSpacing.sm),
                  closeShiftButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: pettyCashButton),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: closeShiftButton),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _outletSection() {
    return _ControlSection(
      title: 'Identitas Outlet',
      description: 'Informasi ini tampil pada struk pembayaran.',
      icon: Icons.storefront_outlined,
      tone: AppSectionTone.warm,
      children: [
        TextField(
          controller: _outletName,
          decoration: const InputDecoration(labelText: 'Nama outlet'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _outletAddress,
          decoration: const InputDecoration(labelText: 'Alamat outlet'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _outletWhatsapp,
          decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _outletInstagram,
          decoration: const InputDecoration(
            labelText: 'Nama pengguna Instagram',
            hintText: '@talagacoffee',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _receiptFooter,
          decoration: const InputDecoration(labelText: 'Teks penutup struk'),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saveOutlet,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simpan outlet'),
          ),
        ),
      ],
    );
  }

  Widget _inventorySection(bool inventoryEnabled) {
    return _ControlSection(
      title: 'Pengelolaan Stok',
      description: 'Kontrol pencatatan persediaan untuk seluruh outlet.',
      icon: Icons.inventory_2_outlined,
      children: [
        SwitchListTile(
          contentPadding: AppSpacing.zero,
          value: inventoryEnabled,
          title: const Text('Aktifkan pengelolaan stok'),
          subtitle: Text(
            inventoryEnabled
                ? 'Stok produk dipantau selama operasional.'
                : 'Pencatatan stok global sedang dinonaktifkan.',
          ),
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .setInventoryEnabled(value);
            ref.invalidate(settingsProvider);
          },
        ),
      ],
    );
  }

  Widget _printerSection(
    PrinterSettingRecord printer,
    PrinterConnectionStatus status,
  ) {
    return _ControlSection(
      title: 'Printer Struk',
      description: 'Pasangkan printer Bluetooth dan tentukan ukuran kertas.',
      icon: Icons.print_outlined,
      tone: AppSectionTone.lake,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusBadge(
              label: status.label,
              status: _printerStatus(status),
              icon: Icons.bluetooth_connected,
            ),
            Text(
              printer.printerName ?? 'Belum ada printer dipilih',
              style: AppTypography.bodyStrong,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ukuran kertas', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<PaperSizeSetting>(
          segments: [
            for (final size in PaperSizeSetting.values)
              ButtonSegment(value: size, label: Text(size.label)),
          ],
          selected: {PaperSizeSetting.fromDb(printer.paperSize)},
          onSelectionChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .savePrinter(paperSize: value.first.name);
            ref.invalidate(printerSettingsProvider);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            OutlinedButton.icon(
              onPressed: _loadingDevices ? null : _loadDevices,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                _loadingDevices ? 'Mencari…' : 'Cari printer yang dipasangkan',
              ),
            ),
            FilledButton.icon(
              onPressed: _selectedDevice == null
                  ? null
                  : () => _connect(_selectedDevice!),
              icon: const Icon(Icons.link),
              label: const Text('Hubungkan'),
            ),
            OutlinedButton.icon(
              onPressed: status == PrinterConnectionStatus.connected
                  ? _disconnect
                  : null,
              icon: const Icon(Icons.link_off),
              label: const Text('Putuskan'),
            ),
            OutlinedButton.icon(
              onPressed: status == PrinterConnectionStatus.connected
                  ? () => _testPrint(PaperSizeSetting.fromDb(printer.paperSize))
                  : null,
              icon: const Icon(Icons.print),
              label: const Text('Cetak uji'),
            ),
          ],
        ),
        if (_devices.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<PrinterDevice>(
            initialValue: _selectedDevice,
            decoration: const InputDecoration(labelText: 'Pilih printer'),
            items: [
              for (final device in _devices)
                DropdownMenuItem(
                  value: device,
                  child: Text('${device.name} (${device.address})'),
                ),
            ],
            onChanged: (value) => setState(() => _selectedDevice = value),
          ),
        ],
      ],
    );
  }

  Widget _cashDrawerSection(
    PrinterSettingRecord printer,
    PrinterConnectionStatus status,
  ) {
    final ready = status == PrinterConnectionStatus.connected;
    return _ControlSection(
      title: 'Laci Kas',
      description: 'Laci mengirim perintah melalui printer ESC/POS.',
      icon: Icons.point_of_sale_outlined,
      children: [
        SwitchListTile(
          contentPadding: AppSpacing.zero,
          value: printer.isCashDrawerEnabled,
          title: const Text('Aktifkan laci kas'),
          subtitle: const Text('Gunakan printer sebagai penghubung laci kas.'),
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .savePrinter(cashDrawerEnabled: value);
            ref.invalidate(printerSettingsProvider);
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: AppStatusBadge(
                label: ready ? 'Siap diuji' : 'Printer belum terhubung',
                status: ready ? AppStatus.success : AppStatus.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tanpa sensor fisik, aplikasi hanya menampilkan status perintah.',
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: printer.isCashDrawerEnabled && ready
                ? _testCashDrawer
                : null,
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Uji buka laci kas'),
          ),
        ),
      ],
    );
  }

  Widget _printerLogSection() {
    final logs = ref.watch(printerLogsProvider);
    return AppSectionCard(
      tone: AppSectionTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat Printer', style: AppTypography.title),
                    Text(
                      'Catatan teknis aktivitas perangkat terbaru.',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          logs.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => AppErrorState(
              title: 'Riwayat printer belum terbaca',
              message: ErrorMessage.from(error),
              onRetry: () => ref.invalidate(printerLogsProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Text(
                  'Belum ada riwayat printer.',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  for (final log in rows.take(8)) _PrinterLogRow(log: log),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveOutlet() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveOutletSettings(
          outletName: _outletName.text,
          outletAddress: _outletAddress.text,
          outletWhatsapp: _outletWhatsapp.text,
          outletInstagram: _outletInstagram.text,
          receiptFooter: _receiptFooter.text,
        );

    ref.invalidate(settingsProvider);
    if (mounted) {
      AppAlert.show(
        context,
        'Pengaturan outlet berhasil disimpan',
        type: AppAlertType.success,
      );
    }
  }

  Future<void> _loadDevices() async {
    if (!await _ensureBluetoothPermissions()) return;
    if (!mounted) return;
    setState(() => _loadingDevices = true);
    try {
      final devices = await ref.read(printerServiceProvider).pairedDevices();
      await ref
          .read(printerLogRepositoryProvider)
          .record(
            eventType: 'discover',
            status: 'success',
            message:
                '${devices.length} printer yang dipasangkan berhasil ditemukan',
          );
      ref.invalidate(printerLogsProvider);
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _selectedDevice = devices.isEmpty ? null : devices.first;
      });
    } catch (error) {
      await ref
          .read(printerLogRepositoryProvider)
          .record(
            eventType: 'discover',
            status: 'failed',
            message: 'Gagal mencari printer yang dipasangkan',
          );
      ref.invalidate(printerLogsProvider);
      if (mounted) {
        AppAlert.show(
          context,
          ErrorMessage.from(error),
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDevices = false);
      }
    }
  }

  Future<void> _connect(PrinterDevice device) async {
    if (!await _ensureBluetoothPermissions()) return;
    if (!mounted) return;
    final user = ref.read(authControllerProvider).value?.user;
    try {
      final connected = await ref.read(printerServiceProvider).connect(device);
      await ref
          .read(settingsRepositoryProvider)
          .savePrinter(
            printerName: device.name,
            printerAddress: device.address,
            lastConnectionStatus: connected ? 'connected' : 'error',
          );
      await ref
          .read(printerLogRepositoryProvider)
          .record(
            eventType: 'connect',
            printerName: device.name,
            printerAddress: device.address,
            status: connected ? 'success' : 'failed',
            message: connected
                ? 'Printer berhasil terhubung'
                : 'Printer gagal terhubung',
          );
      await ref
          .read(auditRepositoryProvider)
          .record(
            actorUserId: user?.id,
            actorUsername: user?.username,
            action: 'printer.connect',
            entityType: 'printer',
            entityId: device.address,
            description: connected
                ? 'Berhasil menghubungkan printer ${device.name}'
                : 'Gagal menghubungkan printer ${device.name}',
          );
      ref.invalidate(printerSettingsProvider);
      ref.invalidate(printerLogsProvider);
      ref.invalidate(auditLogsProvider);
      if (!mounted) return;
      AppAlert.show(
        context,
        connected ? 'Printer berhasil terhubung' : 'Printer gagal terhubung',
        type: connected ? AppAlertType.success : AppAlertType.error,
      );
    } catch (error) {
      if (mounted) {
        AppAlert.show(
          context,
          ErrorMessage.from(error),
          type: AppAlertType.error,
        );
      }
    }
  }

  Future<bool> _ensureBluetoothPermissions() async {
    final permissionService = ref.read(bluetoothPermissionServiceProvider);
    final current = await permissionService.status();
    if (!mounted) return false;
    if (current == BluetoothPermissionState.granted) return true;
    if (current == BluetoothPermissionState.permanentlyDenied) {
      await _showBluetoothPermissionBlocked(permissionService);
      return false;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin printer Bluetooth'),
        content: const Text(
          'Untuk mencari dan menghubungkan printer, Talaga Coffee POS '
          'memerlukan izin Perangkat di Sekitar, Bluetooth, dan Lokasi. '
          'Izin hanya digunakan saat fitur printer dijalankan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (shouldRequest != true || !mounted) return false;

    final result = await permissionService.request();
    if (!mounted) return false;
    if (result == BluetoothPermissionState.granted) return true;
    if (result == BluetoothPermissionState.permanentlyDenied) {
      await _showBluetoothPermissionBlocked(permissionService);
      return false;
    }
    AppAlert.show(
      context,
      'Izin printer ditolak. Printer tidak akan dihubungkan.',
      type: AppAlertType.warning,
    );
    return false;
  }

  Future<void> _showBluetoothPermissionBlocked(
    BluetoothPermissionService permissionService,
  ) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin printer diblokir'),
        content: const Text(
          'Izin Bluetooth atau Lokasi ditolak permanen. Aktifkan izin '
          'Perangkat di Sekitar dan Lokasi melalui Pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await permissionService.openAppSettings();
    }
  }

  Future<void> _disconnect() async {
    final printerValue = ref.read(printerSettingsProvider);
    final printer = printerValue.hasValue ? printerValue.value : null;
    final user = ref.read(authControllerProvider).value?.user;
    await ref.read(printerServiceProvider).disconnect();
    await ref
        .read(settingsRepositoryProvider)
        .savePrinter(lastConnectionStatus: 'disconnected');
    await ref
        .read(printerLogRepositoryProvider)
        .record(
          eventType: 'disconnect',
          printerName: printer?.printerName,
          printerAddress: printer?.printerAddress,
          status: 'success',
          message: 'Printer berhasil diputuskan',
        );
    await ref
        .read(auditRepositoryProvider)
        .record(
          actorUserId: user?.id,
          actorUsername: user?.username,
          action: 'printer.disconnect',
          entityType: 'printer',
          entityId: printer?.printerAddress,
          description: 'Memutuskan printer ${printer?.printerName ?? '-'}',
        );
    ref.invalidate(printerSettingsProvider);
    ref.invalidate(printerLogsProvider);
    ref.invalidate(auditLogsProvider);
  }

  Future<void> _testPrint(PaperSizeSetting paperSize) async {
    final printerValue = ref.read(printerSettingsProvider);
    final printer = printerValue.hasValue ? printerValue.value : null;
    final user = ref.read(authControllerProvider).value?.user;
    final success = await ref.read(printerServiceProvider).testPrint(paperSize);
    await ref
        .read(printerLogRepositoryProvider)
        .record(
          eventType: 'test_print',
          printerName: printer?.printerName,
          printerAddress: printer?.printerAddress,
          status: success ? 'success' : 'failed',
          message: success ? 'Cetak uji berhasil' : 'Cetak uji gagal',
        );
    await ref
        .read(auditRepositoryProvider)
        .record(
          actorUserId: user?.id,
          actorUsername: user?.username,
          action: 'printer.test_print',
          entityType: 'printer',
          entityId: printer?.printerAddress,
          description: success ? 'Cetak uji berhasil' : 'Cetak uji gagal',
        );
    ref.invalidate(printerLogsProvider);
    ref.invalidate(auditLogsProvider);
    if (!mounted) return;
    AppAlert.show(
      context,
      success ? 'Cetak uji berhasil' : 'Cetak uji gagal',
      type: success ? AppAlertType.success : AppAlertType.error,
    );
  }

  Future<void> _testCashDrawer() async {
    final printerValue = ref.read(printerSettingsProvider);
    final printer = printerValue.hasValue ? printerValue.value : null;
    final user = ref.read(authControllerProvider).value?.user;
    final result = await ref.read(cashDrawerServiceProvider).testOpen();
    await ref
        .read(printerLogRepositoryProvider)
        .record(
          eventType: 'cash_drawer_test',
          printerName: printer?.printerName,
          printerAddress: printer?.printerAddress,
          status: result.name == 'commandSent' ? 'success' : 'failed',
          message: result.label,
        );
    await ref
        .read(auditRepositoryProvider)
        .record(
          actorUserId: user?.id,
          actorUsername: user?.username,
          action: 'printer.cash_drawer_test',
          entityType: 'printer',
          entityId: printer?.printerAddress,
          description: 'Uji laci kas: ${result.label}',
        );
    ref.invalidate(printerLogsProvider);
    ref.invalidate(auditLogsProvider);
    if (!mounted) return;
    AppAlert.show(
      context,
      result.label,
      type: result.name == 'commandSent'
          ? AppAlertType.success
          : AppAlertType.error,
    );
  }
}

class _ControlSection extends StatelessWidget {
  const _ControlSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.children,
    this.tone = AppSectionTone.neutral,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> children;
  final AppSectionTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _PrinterLogRow extends StatelessWidget {
  const _PrinterLogRow({required this.log});

  final PrinterLogRecord log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.status == 'success'
                ? Icons.check_circle_outline
                : log.status == 'failed'
                ? Icons.error_outline
                : Icons.info_outline,
            color: log.status == 'failed'
                ? scheme.error
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _printerEventLabel(log.eventType),
                      style: AppTypography.bodyStrong,
                    ),
                    AppStatusBadge(
                      label: _printerLogStatusLabel(log.status),
                      status: _logStatus(log.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _printerLogMessage(log.message),
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  DateFormatter.human(log.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
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

AppStatus _printerStatus(PrinterConnectionStatus status) => switch (status) {
  PrinterConnectionStatus.connected => AppStatus.success,
  PrinterConnectionStatus.connecting => AppStatus.warning,
  PrinterConnectionStatus.error => AppStatus.danger,
  PrinterConnectionStatus.disconnected => AppStatus.neutral,
};

AppStatus _logStatus(String status) => switch (status) {
  'success' => AppStatus.success,
  'failed' => AppStatus.danger,
  'pending' => AppStatus.warning,
  _ => AppStatus.neutral,
};

String _printerEventLabel(String eventType) => switch (eventType) {
  'discover' => 'Pencarian printer',
  'connect' => 'Menghubungkan printer',
  'disconnect' => 'Memutuskan printer',
  'test_print' => 'Cetak uji',
  'cash_drawer_test' => 'Uji laci kas',
  'print' => 'Mencetak struk',
  _ => 'Aktivitas printer',
};

String _printerLogStatusLabel(String status) => switch (status) {
  'success' => 'Berhasil',
  'failed' => 'Gagal',
  'pending' => 'Menunggu',
  _ => 'Status tidak dikenal',
};

String _printerLogMessage(String message) {
  final foundDevices = RegExp(
    r'^Found (\d+) paired printer device\(s\)$',
  ).firstMatch(message);
  if (foundDevices != null) {
    return '${foundDevices.group(1)} printer yang dipasangkan berhasil ditemukan';
  }

  return switch (message) {
    'Printer connected' => 'Printer berhasil terhubung',
    'Printer connection failed' => 'Printer gagal terhubung',
    'Printer disconnected' => 'Printer berhasil diputuskan',
    'Test print success' => 'Cetak uji berhasil',
    'Test print failed' => 'Cetak uji gagal',
    'Not ready' || 'Not Ready' => 'Belum siap',
    'Ready' => 'Siap',
    'Command sent' || 'Command Sent' => 'Perintah terkirim',
    'Failed' => 'Gagal',
    _ => message,
  };
}

class BukaShiftInlineForm extends ConsumerStatefulWidget {
  const BukaShiftInlineForm({super.key});

  @override
  ConsumerState<BukaShiftInlineForm> createState() =>
      _BukaShiftInlineFormState();
}

class _BukaShiftInlineFormState extends ConsumerState<BukaShiftInlineForm> {
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _cashierNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Kasir',
              hintText: 'Nama yang tampil pada struk',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama kasir wajib diisi'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _openingCashController,
            decoration: const InputDecoration(
              labelText: 'Modal Awal Tunai',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: const [IdrAmountInputFormatter()],
            validator: (value) {
              if (IdrAmountInputFormatter.parse(value ?? '') == null) {
                return 'Modal awal wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppLayout.cashierControlHeight,
            child: FilledButton.icon(
              onPressed: _opening ? null : _openShift,
              icon: _opening
                  ? SizedBox.square(
                      dimension: AppSpacing.lg,
                      child: CircularProgressIndicator(
                        strokeWidth: AppLayout.progressStrokeWidth,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.key_outlined),
              label: Text(_opening ? 'Membuka shift…' : 'Mulai Shift'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openShift() async {
    if (_opening || !_formKey.currentState!.validate()) {
      return;
    }
    final user = ref.read(authControllerProvider).value?.user;
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
