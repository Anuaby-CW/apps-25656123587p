import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_message.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

class AddonsScreen extends ConsumerWidget {
  const AddonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    final roleTokens = AppRoleTokens.of(context);

    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'MENU & RACIKAN',
            title: 'Pilihan Tambahan',
            description:
                'Atur pilihan ekstra dan harga yang dapat dipilih saat transaksi.',
            action: FilledButton.icon(
              onPressed: () => _openAddonDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pilihan'),
            ),
          ),
          SizedBox(height: roleTokens.sectionGap),
          Expanded(
            child: catalog.when(
              loading: () =>
                  const AppLoadingState(message: 'Menyiapkan add-ons…'),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
              ),
              data: (snapshot) {
                if (snapshot.addons.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.add_circle_outline,
                    title: 'Belum ada pilihan tambahan',
                    message:
                        'Tambahkan pilihan ekstra untuk melengkapi racikan menu.',
                    actionLabel: 'Tambah Pilihan',
                    onAction: () => _openAddonDialog(context),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    if (constraints.maxWidth >= AppLayout.expandedBreakpoint &&
                        textScale <= 1.3) {
                      return _AddonLedger(snapshot: snapshot);
                    }
                    return _AddonCards(snapshot: snapshot);
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

class _AddonLedger extends ConsumerWidget {
  const _AddonLedger({required this.snapshot});

  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSectionCard(
      tone: AppSectionTone.plain,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ADD-ON')),
              DataColumn(label: Text('HARGA')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('AKSI')),
            ],
            rows: [
              for (final addon in snapshot.addons)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(addon.name),
                        ],
                      ),
                    ),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          MoneyFormatter.format(addon.price),
                          style: AppTypography.bodyStrong.merge(
                            AppTypography.monetary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      AppStatusBadge(
                        label: addon.isActive ? 'Aktif' : 'Nonaktif',
                        status: addon.isActive
                            ? AppStatus.success
                            : AppStatus.neutral,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit ${addon.name}',
                            onPressed: () =>
                                _openAddonDialog(context, addon: addon),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            tooltip: 'Hapus ${addon.name}',
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => _deleteAddon(context, ref, addon),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonCards extends ConsumerWidget {
  const _AddonCards({required this.snapshot});

  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: snapshot.addons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final addon = snapshot.addons[index];
        return AppSectionCard(
          tone: AppSectionTone.plain,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          MoneyFormatter.format(addon.price),
                          style: AppTypography.bodyStrong.merge(
                            AppTypography.monetary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusBadge(
                    label: addon.isActive ? 'Aktif' : 'Nonaktif',
                    status: addon.isActive
                        ? AppStatus.success
                        : AppStatus.neutral,
                  ),
                  IconButton(
                    tooltip: 'Edit ${addon.name}',
                    onPressed: () => _openAddonDialog(context, addon: addon),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Hapus ${addon.name}',
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteAddon(context, ref, addon),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openAddonDialog(BuildContext context, {AddonRecord? addon}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddonDialog(addon: addon),
  );
}

Future<void> _deleteAddon(
  BuildContext context,
  WidgetRef ref,
  AddonRecord addon,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Pilihan Tambahan'),
      content: const Text(
        'Pilihan tambahan akan dihapus dari katalog transaksi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  try {
    await ref.read(catalogRepositoryProvider).deleteAddon(addon.id);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(catalogSnapshotProvider);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

class _AddonDialog extends ConsumerStatefulWidget {
  const _AddonDialog({this.addon});

  final AddonRecord? addon;

  @override
  ConsumerState<_AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends ConsumerState<_AddonDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.addon?.name ?? '');
    _price = TextEditingController(text: widget.addon?.price.toString() ?? '');
    _active = widget.addon?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(MediaQuery.sizeOf(context).width);
    final title = widget.addon == null
        ? 'Tambah Pilihan Tambahan'
        : 'Edit Pilihan Tambahan';
    final content = _buildContent(context);
    final saveButton = _buildSaveButton();

    if (compact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
            title: Text(title),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: saveButton),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.dialogSmallMaxWidth,
        ),
        child: content,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        saveButton,
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Detail pilihan tambahan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama pilihan'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _price,
            decoration: const InputDecoration(
              labelText: 'Harga',
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            contentPadding: AppSpacing.zero,
            value: _active,
            onChanged: _saving
                ? null
                : (value) => setState(() => _active = value),
            title: const Text('Aktif di transaksi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox.square(
              dimension: AppSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: AppLayout.progressStrokeWidth,
              ),
            )
          : const Icon(Icons.save_outlined),
      label: const Text('Simpan'),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final price = int.tryParse(_price.text.trim());
    if (price == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka yang valid')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .saveAddon(
            id: widget.addon?.id,
            name: _name.text,
            price: price,
            isActive: _active,
          );
      ref.invalidate(adminCatalogSnapshotProvider);
      ref.invalidate(catalogSnapshotProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
