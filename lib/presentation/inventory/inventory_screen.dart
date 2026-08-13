import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeader(
            eyebrow: 'OPERASIONAL',
            title: 'Papan Persediaan',
            description:
                'Pantau jumlah tersedia dan batas minimum setiap produk.',
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Expanded(
            child: catalog.when(
              loading: () =>
                  const AppLoadingState(message: 'Menyiapkan data persediaan…'),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
              ),
              data: (snapshot) {
                final trackedInventory = snapshot.trackedInventory;
                if (trackedInventory.isEmpty) {
                  return const AppEmptyState(
                    title: 'Data stok kosong',
                    message:
                        'Produk yang mengaktifkan pelacakan stok akan tampil di sini.',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                final productById = {
                  for (final product in snapshot.products) product.id: product,
                };
                final lowCount = trackedInventory
                    .where((row) => row.quantity <= row.lowStockThreshold)
                    .length;
                final scheme = Theme.of(context).colorScheme;
                final semantic = AppSemanticColors.of(context);
                final attentionColor = lowCount > 0
                    ? scheme.error
                    : semantic.success;
                final summaryForeground = lowCount > 0
                    ? scheme.onErrorContainer
                    : semantic.onSuccessContainer;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionCard(
                      tone: lowCount > 0
                          ? AppSectionTone.attention
                          : AppSectionTone.lake,
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            lowCount > 0
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: attentionColor,
                          ),
                          Text(
                            lowCount > 0
                                ? '$lowCount produk perlu perhatian'
                                : 'Seluruh stok berada di atas batas minimum',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.merge(AppTypography.monetary),
                          ),
                          Text(
                            '${trackedInventory.length} produk dilacak',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.merge(AppTypography.monetary)
                                .copyWith(color: summaryForeground),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ListView.separated(
                        itemCount: trackedInventory.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final row = trackedInventory[index];
                          final product = productById[row.productId];
                          final isLow = row.quantity <= row.lowStockThreshold;
                          return _InventoryRow(
                            productName: product?.name ?? row.productId,
                            quantity: row.quantity,
                            threshold: row.lowStockThreshold,
                            isLow: isLow,
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (_) => _InventoryDialog(
                                productId: row.productId,
                                productName: product?.name ?? row.productId,
                                quantity: row.quantity,
                                lowStockThreshold: row.lowStockThreshold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.productName,
    required this.quantity,
    required this.threshold,
    required this.isLow,
    required this.onTap,
  });

  final String productName;
  final int quantity;
  final int threshold;
  final bool isLow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final statusColor = isLow ? scheme.error : semantic.success;
    final amountColor = isLow ? scheme.onErrorContainer : semantic.success;
    return AppSectionCard(
      tone: isLow ? AppSectionTone.attention : AppSectionTone.plain,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppLayout.compactBreakpoint ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inventory_2_outlined, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Batas minimum $threshold',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLow
                            ? scheme.onErrorContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final status = AppStatusBadge(
            label: isLow ? 'Stok menipis' : 'Stok aman',
            status: isLow ? AppStatus.danger : AppStatus.success,
            icon: isLow
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
          );
          final amount = Text(
            quantity.toString(),
            style: Theme.of(context).textTheme.headlineSmall
                ?.merge(AppTypography.monetary)
                .copyWith(color: amountColor),
          );
          final edit = SizedBox.square(
            dimension: 48,
            child: IconButton.filledTonal(
              tooltip: 'Sesuaikan stok $productName',
              onPressed: onTap,
              icon: const Icon(Icons.tune),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    status,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        amount,
                        const SizedBox(width: AppSpacing.sm),
                        edit,
                      ],
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: identity),
              Expanded(flex: 2, child: status),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: amount),
              ),
              const SizedBox(width: AppSpacing.md),
              edit,
            ],
          );
        },
      ),
    );
  }
}

class _InventoryDialog extends ConsumerStatefulWidget {
  const _InventoryDialog({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.lowStockThreshold,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int lowStockThreshold;

  @override
  ConsumerState<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends ConsumerState<_InventoryDialog> {
  late final TextEditingController _quantity;
  late final TextEditingController _lowStockThreshold;
  late final TextEditingController _notes;
  String _type = 'adjustment';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: widget.quantity.toString());
    _lowStockThreshold = TextEditingController(
      text: widget.lowStockThreshold.toString(),
    );
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _lowStockThreshold.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact =
        AppLayout.isCompact(media.size.width) ||
        AppLayout.isCompactHeight(media.size.height) ||
        media.textScaler.scale(1) > 1.3;
    final cancelButton = TextButton(
      onPressed: _saving ? null : () => Navigator.of(context).pop(),
      child: const Text('Batal'),
    );
    final saveButton = FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox.square(
              dimension: AppSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: AppLayout.progressStrokeWidth,
              ),
            )
          : const Icon(Icons.save_outlined),
      label: Text(_saving ? 'Menyimpan…' : 'Simpan'),
    );

    if (compact) {
      final scheme = Theme.of(context).colorScheme;
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Sesuaikan Stok ${widget.productName}'),
            leading: IconButton(
              tooltip: 'Tutup',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: AppSpacing.allMd,
              child: _buildDialogContent(context, allowSplit: false),
            ),
          ),
          bottomNavigationBar: Material(
            color: scheme.surface,
            child: SafeArea(
              minimum: AppSpacing.allMd,
              child: Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: cancelButton)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: SizedBox(height: 48, child: saveButton)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text('Sesuaikan Stok ${widget.productName}'),
      content: SizedBox(
        width: AppLayout.dialogLargeMaxWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
          child: SingleChildScrollView(
            child: _buildDialogContent(context, allowSplit: true),
          ),
        ),
      ),
      actions: [
        SizedBox(height: 48, child: cancelButton),
        SizedBox(height: 48, child: saveButton),
      ],
    );
  }

  Widget _buildDialogContent(BuildContext context, {required bool allowSplit}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final split =
            allowSplit &&
            constraints.maxWidth >= AppLayout.compactBreakpoint &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final form = _buildForm(context);
        final history = _buildHistory(context);
        return split
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(child: history),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  form,
                  const SizedBox(height: AppSpacing.xl),
                  history,
                ],
              );
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Penyesuaian', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _quantity,
            decoration: const InputDecoration(labelText: 'Stok akhir'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _lowStockThreshold,
            decoration: const InputDecoration(
              labelText: 'Batas minimum stok',
              helperText:
                  'Dashboard memberi peringatan saat stok mencapai batas ini.',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Jenis perubahan stok',
            ),
            items: const [
              DropdownMenuItem(value: 'adjustment', child: Text('Penyesuaian')),
              DropdownMenuItem(value: 'restock', child: Text('Stok masuk')),
              DropdownMenuItem(value: 'waste', child: Text('Rusak / Terbuang')),
              DropdownMenuItem(value: 'correction', child: Text('Koreksi')),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Catatan'),
            minLines: 2,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionTone.lake,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Riwayat stok terakhir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder(
            future: ref
                .read(catalogRepositoryProvider)
                .stockMovementsForProduct(widget.productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text(ErrorMessage.from(snapshot.error));
              }
              final movements = snapshot.data ?? [];
              if (movements.isEmpty) {
                return const Text('Belum ada riwayat perubahan stok.');
              }
              return Column(
                children: [
                  for (final movement in movements.take(8))
                    ListTile(
                      contentPadding: AppSpacing.zero,
                      leading: const Icon(Icons.timeline),
                      title: Text(
                        '${_movementLabel(movement.type)} '
                        '(${movement.quantityChange >= 0 ? '+' : ''}${movement.quantityChange})',
                      ),
                      subtitle: Text(
                        '${DateFormatter.human(movement.createdAt)} • '
                        'stok akhir ${movement.quantityAfter}'
                        '${movement.notes == null ? '' : ' • ${movement.notes}'}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(authControllerProvider).value?.user;
    final quantity = int.tryParse(_quantity.text.trim());
    final threshold = int.tryParse(_lowStockThreshold.text.trim());
    if (quantity == null || quantity < 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Stok akhir harus berupa angka minimal 0.'),
        ),
      );
      return;
    }
    if (threshold == null || threshold < 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Batas minimum stok harus berupa angka minimal 0.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .adjustInventory(
            productId: widget.productId,
            quantityAfter: quantity,
            lowStockThreshold: threshold,
            type: _type,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            actorUserId: user?.id,
            actorUsername: user?.username,
          );
      ref.invalidate(adminCatalogSnapshotProvider);
      ref.invalidate(catalogSnapshotProvider);
      ref.invalidate(auditLogsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Stok dan batas minimum berhasil disimpan.'),
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _movementLabel(String value) => switch (value) {
    'adjustment' => 'Penyesuaian',
    'restock' => 'Stok masuk',
    'waste' => 'Rusak / Terbuang',
    'correction' => 'Koreksi',
    'initial_stock' => 'Stok awal',
    'sale' => 'Penjualan',
    _ => value,
  };
}
