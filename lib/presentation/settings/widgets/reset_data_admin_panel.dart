import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_message.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/app_page_frame.dart';
import '../../../widgets/common/app_section_card.dart';
import '../../providers/app_providers.dart';
import '../../../widgets/common/app_alert.dart';

class ResetDataAdminPanel extends ConsumerStatefulWidget {
  const ResetDataAdminPanel({super.key});

  @override
  ConsumerState<ResetDataAdminPanel> createState() =>
      _ResetDataAdminPanelState();
}

class _ResetDataAdminPanelState extends ConsumerState<ResetDataAdminPanel> {
  bool _clearTransactional = false;
  bool _clearLogs = false;
  bool _clearCache = false;

  bool _isLoading = false;

  bool get _hasSelection => _clearTransactional || _clearLogs || _clearCache;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Panel Reset Data')),
        body: AppPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                tone: AppSectionTone.attention,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peringatan Data Lokal',
                            style: AppTypography.bodyStrong.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Data yang direset akan hilang permanen dari perangkat dan tidak dapat dipulihkan dari server.',
                            style: AppTypography.body.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Pilih data yang akan direset',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSectionCard(
                tone: AppSectionTone.plain,
                child: Column(
                  children: [
                    _buildCheckbox(
                      title: 'Riwayat Transaksi',
                      subtitle:
                          'Pesanan, pembayaran, pergerakan stok penjualan, kas kecil, dan shift aktif.',
                      value: _clearTransactional,
                      onChanged: (v) =>
                          setState(() => _clearTransactional = v ?? false),
                    ),
                    _buildCheckbox(
                      title: 'Log Aktivitas & Printer',
                      subtitle:
                          'Riwayat audit aktivitas pengguna dan hasil cetak printer.',
                      value: _clearLogs,
                      onChanged: (v) => setState(() => _clearLogs = v ?? false),
                    ),
                    _buildCheckbox(
                      title: 'Katalog & Persediaan Bawaan',
                      subtitle:
                          'Kategori, produk, add-on, biji kopi, stok, dan riwayat stok diganti dengan data bawaan lokal.',
                      value: _clearCache,
                      onChanged: (v) =>
                          setState(() => _clearCache = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.hero),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: AppLayout.adminPrimaryControlHeight,
            child: FilledButton.icon(
              onPressed: _hasSelection && !_isLoading ? _executeReset : null,
              icon: _isLoading
                  ? SizedBox.square(
                      dimension: AppSpacing.lg,
                      child: CircularProgressIndicator(
                        color: scheme.onError,
                        strokeWidth: AppLayout.progressStrokeWidth,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_isLoading ? 'Mereset data…' : 'Reset Data Terpilih'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return CheckboxListTile(
      title: Text(
        title,
        style: AppTypography.bodyStrong.copyWith(
          color: isDestructive ? scheme.error : scheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: isDestructive ? scheme.error : scheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: isDestructive ? scheme.error : scheme.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _executeReset() async {
    final scheme = Theme.of(context).colorScheme;
    final session = ref.read(authControllerProvider).value;
    if (session == null || session.user == null) return;

    final passwordController = TextEditingController();
    bool isDialogLoading = false;
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Konfirmasi Reset'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anda akan menghapus kategori data berikut:'),
                  const SizedBox(height: AppSpacing.sm),
                  if (_clearTransactional) const Text('• Riwayat Transaksi'),
                  if (_clearLogs) const Text('• Log Aktivitas & Printer'),
                  if (_clearCache) const Text('• Katalog & Persediaan Bawaan'),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Masukkan kata sandi Admin untuk melanjutkan:'),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading
                      ? null
                      : () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isDialogLoading = true;
                            error = null;
                          });

                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .login(
                                  session.user!.username,
                                  passwordController.text,
                                );
                            if (context.mounted) {
                              Navigator.of(ctx).pop(true);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isDialogLoading = false;
                              error = 'Kata sandi salah';
                            });
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDialogLoading) ...[
                        SizedBox.square(
                          dimension: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppLayout.progressStrokeWidth,
                            color: scheme.onError,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ] else ...[
                        const Icon(Icons.delete_forever_outlined),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(isDialogLoading ? 'Memverifikasi…' : 'Reset Data'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(resetRepositoryProvider);
        await repo.resetSelected(
          transactionalData: _clearTransactional,
          sessionLogs: _clearLogs,
          referenceData: _clearCache,
          customers: false,
        );

        // invalidate relevant providers
        if (_clearTransactional) {
          ref.invalidate(ordersProvider);
          ref.invalidate(shiftControllerProvider);
          ref.invalidate(shiftCashSalesProvider);
          ref.invalidate(shiftPettyCashProvider);
          ref.invalidate(pettyCashControllerProvider);
        }
        if (_clearCache) {
          ref.invalidate(catalogSnapshotProvider);
          ref.invalidate(adminCatalogSnapshotProvider);
        }
        if (_clearLogs) {
          ref.invalidate(auditLogsProvider);
          ref.invalidate(printerLogsProvider);
        }

        await ref
            .read(auditRepositoryProvider)
            .record(
              actorUserId: session.user!.id,
              actorUsername: session.user!.username,
              action: 'admin.reset_data',
              entityType: 'database',
              description:
                  'Admin mereset data. Kategori: '
                  '${_clearTransactional ? 'Transaksi ' : ''}'
                  '${_clearLogs ? 'Log ' : ''}'
                  '${_clearCache ? 'Katalog' : ''}',
            );

        if (mounted) {
          AppAlert.show(
            context,
            'Reset data berhasil dijalankan',
            type: AppAlertType.success,
          );
          if (context.mounted) {
            Navigator.of(context).pop(); // Kembali ke pengaturan
          }
        }
      } catch (e) {
        if (mounted) {
          AppAlert.show(
            context,
            'Gagal reset data: ${ErrorMessage.from(e)}',
            type: AppAlertType.error,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
