import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_message.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

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
            title: 'Kategori',
            description:
                'Susun peta menu utama dan subkategori yang tampil pada POS.',
            action: FilledButton.icon(
              onPressed: () => _openCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
            ),
          ),
          SizedBox(height: roleTokens.sectionGap),
          Expanded(
            child: catalog.when(
              loading: () =>
                  const AppLoadingState(message: 'Menyiapkan peta kategori…'),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
              ),
              data: (snapshot) {
                if (snapshot.categories.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'Belum ada kategori',
                    message:
                        'Tambahkan kategori utama lalu susun subkategori menu.',
                    actionLabel: 'Tambah Kategori',
                    onAction: () => _openCategoryDialog(context),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    if (constraints.maxWidth >= AppLayout.expandedBreakpoint &&
                        textScale <= 1.3) {
                      return _CategoryLedger(snapshot: snapshot);
                    }
                    return _CategoryCards(snapshot: snapshot);
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

class _CategoryLedger extends ConsumerWidget {
  const _CategoryLedger({required this.snapshot});

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
              DataColumn(label: Text('KATEGORI')),
              DataColumn(label: Text('INDUK')),
              DataColumn(label: Text('JENIS')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('URUTAN')),
              DataColumn(label: Text('AKSI')),
            ],
            rows: [
              for (var index = 0; index < snapshot.categories.length; index++)
                _row(context, ref, snapshot.categories[index], index),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    WidgetRef ref,
    CategoryRecord category,
    int index,
  ) {
    final parent = category.parentId == null
        ? null
        : snapshot.categoryById[category.parentId!];
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Icon(
                parent == null
                    ? Icons.account_tree_outlined
                    : Icons.subdirectory_arrow_right,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(category.name),
            ],
          ),
        ),
        DataCell(Text(parent?.name ?? 'Kategori utama')),
        DataCell(Text(_categoryTypeLabel(category.type))),
        DataCell(
          AppStatusBadge(
            label: category.isActive ? 'Aktif' : 'Nonaktif',
            status: category.isActive ? AppStatus.success : AppStatus.neutral,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${index + 1}'),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Naikkan urutan ${category.name}',
                onPressed: index == 0
                    ? null
                    : () => _moveCategory(ref, snapshot, index, index - 1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Turunkan urutan ${category.name}',
                onPressed: index == snapshot.categories.length - 1
                    ? null
                    : () => _moveCategory(ref, snapshot, index, index + 1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit ${category.name}',
                onPressed: () =>
                    _openCategoryDialog(context, category: category),
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Hapus ${category.name}',
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _deleteCategory(context, ref, category),
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                label: 'Status ${category.name}',
                toggled: category.isActive,
                child: Switch(
                  value: category.isActive,
                  onChanged: (value) =>
                      _setCategoryActive(context, ref, category, value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCards extends ConsumerWidget {
  const _CategoryCards({required this.snapshot});

  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      itemCount: snapshot.categories.length,
      buildDefaultDragHandles: false,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        await _moveCategory(ref, snapshot, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final category = snapshot.categories[index];
        final parent = category.parentId == null
            ? null
            : snapshot.categoryById[category.parentId!];
        return Padding(
          key: ValueKey(category.id),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppSectionCard(
            tone: parent == null ? AppSectionTone.lake : AppSectionTone.plain,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      parent == null
                          ? Icons.account_tree_outlined
                          : Icons.subdirectory_arrow_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            parent == null
                                ? 'Kategori utama'
                                : 'Di bawah ${parent.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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
                      label: _categoryTypeLabel(category.type),
                      status: AppStatus.info,
                    ),
                    AppStatusBadge(
                      label: category.isActive ? 'Aktif' : 'Nonaktif',
                      status: category.isActive
                          ? AppStatus.success
                          : AppStatus.neutral,
                    ),
                    Tooltip(
                      message: 'Ubah urutan ${category.name}',
                      child: ReorderableDragStartListener(
                        index: index,
                        child: const SizedBox.square(
                          dimension: AppLayout.adminPrimaryControlHeight,
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit ${category.name}',
                      onPressed: () =>
                          _openCategoryDialog(context, category: category),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus ${category.name}',
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _deleteCategory(context, ref, category),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    Semantics(
                      label: 'Status ${category.name}',
                      toggled: category.isActive,
                      child: Switch(
                        value: category.isActive,
                        onChanged: (value) =>
                            _setCategoryActive(context, ref, category, value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _moveCategory(
  WidgetRef ref,
  CatalogSnapshot snapshot,
  int oldIndex,
  int newIndex,
) async {
  if (oldIndex == newIndex ||
      oldIndex < 0 ||
      newIndex < 0 ||
      oldIndex >= snapshot.categories.length ||
      newIndex >= snapshot.categories.length) {
    return;
  }

  final list = List<CategoryRecord>.from(snapshot.categories);
  final item = list.removeAt(oldIndex);
  list.insert(newIndex, item);

  for (int index = 0; index < list.length; index++) {
    final category = list[index];
    await ref
        .read(catalogRepositoryProvider)
        .saveCategory(
          id: category.id,
          name: category.name,
          type: category.type,
          parentId: category.parentId,
          isActive: category.isActive,
          sortOrder: index,
        );
  }
  ref.invalidate(adminCatalogSnapshotProvider);
  ref.invalidate(catalogSnapshotProvider);
}

Future<void> _openCategoryDialog(
  BuildContext context, {
  CategoryRecord? category,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CategoryFormDialog(category: category),
  );
}

Future<void> _deleteCategory(
  BuildContext context,
  WidgetRef ref,
  CategoryRecord category,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Kategori'),
      content: const Text(
        'Kategori akan dihapus. Pastikan tidak ada produk yang masih bergantung pada kategori ini.',
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
    await ref.read(catalogRepositoryProvider).deleteCategory(category.id);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(catalogSnapshotProvider);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

Future<void> _setCategoryActive(
  BuildContext context,
  WidgetRef ref,
  CategoryRecord category,
  bool value,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(catalogRepositoryProvider)
        .setCategoryActive(category, value);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(catalogSnapshotProvider);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  const _CategoryFormDialog({this.category});

  final CategoryRecord? category;

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  late final TextEditingController _name;
  String _type = 'drink';
  String? _parentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _type = category?.type ?? 'drink';
    _parentId = category?.parentId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    final compact = AppLayout.isCompact(MediaQuery.sizeOf(context).width);
    final title = widget.category == null ? 'Tambah Kategori' : 'Edit Kategori';
    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppLayout.dialogSmallMaxWidth,
      ),
      child: catalog.when(
        loading: () =>
            const AppLoadingState(message: 'Menyiapkan kategori induk…'),
        error: (error, _) => AppErrorState(
          message: ErrorMessage.from(error),
          onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
        ),
        data: (snapshot) {
          final parents = snapshot.categories
              .where((category) => category.parentId == null)
              .toList();
          return AppSectionCard(
            tone: AppSectionTone.plain,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Struktur menu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama kategori'),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_saving,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Jenis', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final entry in const [
                      ('drink', 'Minuman'),
                      ('food', 'Makanan'),
                      ('addon', 'Tambahan'),
                    ])
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: _type == entry.$1,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _type = entry.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdownField<String?>(
                  initialValue: _parentId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori induk',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('- kategori utama -'),
                    ),
                    for (final parent in parents)
                      DropdownMenuItem<String?>(
                        value: parent.id,
                        child: Text(parent.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _parentId = value),
                  enabled: !_saving,
                ),
              ],
            ),
          );
        },
      ),
    );
    final saveButton = _buildSaveButton();

    if (compact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Tutup',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
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
      content: content,
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        saveButton,
      ],
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
    setState(() => _saving = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .saveCategory(
            id: widget.category?.id,
            name: _name.text,
            type: _type,
            parentId: _parentId,
            isActive: widget.category?.isActive ?? true,
          );
      ref.invalidate(adminCatalogSnapshotProvider);
      ref.invalidate(catalogSnapshotProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _categoryTypeLabel(String value) => switch (value) {
  'drink' => 'Minuman',
  'food' => 'Makanan',
  'addon' => 'Tambahan',
  _ => value,
};
