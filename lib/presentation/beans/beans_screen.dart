import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routing/app_destination.dart';
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

class BeansScreen extends ConsumerWidget {
  const BeansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    return _RacikanWorkspace(
      selected: AppDestination.beans,
      title: 'Biji Kopi',
      description:
          'Kelola pilihan biji dan harga Panas/Dingin untuk racikan Manual Brew.',
      addLabel: 'Tambah Biji Kopi',
      onAdd: () => _openBeanDialog(context),
      content: catalog.when(
        loading: () =>
            const AppLoadingState(message: 'Menyiapkan pilihan biji kopi…'),
        error: (error, _) => AppErrorState(
          message: ErrorMessage.from(error),
          onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
        ),
        data: (snapshot) {
          if (snapshot.beans.isEmpty) {
            return AppEmptyState(
              icon: Icons.coffee_outlined,
              title: 'Belum ada biji kopi',
              message:
                  'Tambahkan pilihan biji untuk melengkapi menu Manual Brew.',
              actionLabel: 'Tambah Biji Kopi',
              onAction: () => _openBeanDialog(context),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              if (constraints.maxWidth >= AppLayout.largeBreakpoint &&
                  textScale <= 1.3) {
                return _BeanLedger(snapshot: snapshot);
              }
              return _BeanCards(snapshot: snapshot);
            },
          );
        },
      ),
    );
  }
}

class _RacikanWorkspace extends StatelessWidget {
  const _RacikanWorkspace({
    required this.selected,
    required this.title,
    required this.description,
    required this.addLabel,
    required this.onAdd,
    required this.content,
  });

  final AppDestination selected;
  final String title;
  final String description;
  final String addLabel;
  final VoidCallback onAdd;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final roleTokens = AppRoleTokens.of(context);
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'MENU & RACIKAN · WORKSPACE RACIKAN',
            title: title,
            description: description,
            action: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ),
          SizedBox(height: roleTokens.sectionGap),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _BeanLedger extends ConsumerWidget {
  const _BeanLedger({required this.snapshot});

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
              DataColumn(label: Text('BIJI KOPI')),
              DataColumn(label: Text('HARGA PANAS')),
              DataColumn(label: Text('HARGA DINGIN')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('AKSI')),
            ],
            rows: [
              for (final bean in snapshot.beans)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            Icons.coffee_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(bean.name),
                        ],
                      ),
                    ),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          MoneyFormatter.format(bean.hotPrice),
                          style: AppTypography.bodyStrong.merge(
                            AppTypography.monetary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          MoneyFormatter.format(bean.icePrice),
                          style: AppTypography.bodyStrong.merge(
                            AppTypography.monetary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      AppStatusBadge(
                        label: bean.isActive ? 'Aktif' : 'Nonaktif',
                        status: bean.isActive
                            ? AppStatus.success
                            : AppStatus.neutral,
                      ),
                    ),
                    DataCell(
                      _EntityActions(
                        entityName: bean.name,
                        onEdit: () => _openBeanDialog(context, bean: bean),
                        onDelete: () => _deleteBean(context, ref, bean),
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

class _BeanCards extends ConsumerWidget {
  const _BeanCards({required this.snapshot});

  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: snapshot.beans.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final bean = snapshot.beans[index];
        return AppSectionCard(
          tone: AppSectionTone.plain,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.coffee_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      bean.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.xs,
                children: [
                  _PriceLabel(
                    label: 'Panas',
                    value: MoneyFormatter.format(bean.hotPrice),
                  ),
                  _PriceLabel(
                    label: 'Dingin',
                    value: MoneyFormatter.format(bean.icePrice),
                  ),
                ],
              ),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusBadge(
                    label: bean.isActive ? 'Aktif' : 'Nonaktif',
                    status: bean.isActive
                        ? AppStatus.success
                        : AppStatus.neutral,
                  ),
                  _EntityActions(
                    entityName: bean.name,
                    onEdit: () => _openBeanDialog(context, bean: bean),
                    onDelete: () => _deleteBean(context, ref, bean),
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

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.merge(AppTypography.monetary),
        ),
      ],
    );
  }
}

class _EntityActions extends StatelessWidget {
  const _EntityActions({
    this.entityName,
    required this.onEdit,
    required this.onDelete,
  });

  final String? entityName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: entityName == null ? 'Edit' : 'Edit $entityName',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: entityName == null ? 'Hapus' : 'Hapus $entityName',
          color: Theme.of(context).colorScheme.error,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

Future<void> _openBeanDialog(BuildContext context, {BeanRecord? bean}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BeanDialog(bean: bean),
  );
}

Future<void> _deleteBean(
  BuildContext context,
  WidgetRef ref,
  BeanRecord bean,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await _confirmDelete(
    context,
    title: 'Hapus Biji Kopi',
    message: 'Biji kopi akan dihapus dari pilihan racikan Manual Brew.',
  );
  if (!confirmed) {
    return;
  }
  try {
    await ref.read(catalogRepositoryProvider).deleteBean(bean.id);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(catalogSnapshotProvider);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
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
      ) ??
      false;
}

class _BeanDialog extends ConsumerStatefulWidget {
  const _BeanDialog({this.bean});

  final BeanRecord? bean;

  @override
  ConsumerState<_BeanDialog> createState() => _BeanDialogState();
}

class _BeanDialogState extends ConsumerState<_BeanDialog> {
  late final TextEditingController _name;
  late final TextEditingController _hot;
  late final TextEditingController _ice;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final bean = widget.bean;
    _name = TextEditingController(text: bean?.name ?? '');
    _hot = TextEditingController(text: bean?.hotPrice.toString() ?? '');
    _ice = TextEditingController(text: bean?.icePrice.toString() ?? '');
    _active = bean?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _hot.dispose();
    _ice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(MediaQuery.sizeOf(context).width);
    final title = widget.bean == null ? 'Tambah Biji Kopi' : 'Edit Biji Kopi';
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
            'Identitas dan harga',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama biji kopi'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _hot,
            decoration: const InputDecoration(
              labelText: 'Harga Panas',
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _ice,
            decoration: const InputDecoration(
              labelText: 'Harga Dingin',
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
    final hotPrice = int.tryParse(_hot.text.trim());
    final icePrice = int.tryParse(_ice.text.trim());
    if (hotPrice == null || icePrice == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka yang valid')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .saveBean(
            id: widget.bean?.id,
            name: _name.text,
            hotPrice: hotPrice,
            icePrice: icePrice,
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
