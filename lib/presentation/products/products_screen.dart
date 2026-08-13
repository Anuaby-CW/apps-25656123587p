import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/id_generator.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
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

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

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
            title: 'Produk',
            description:
                'Kelola identitas menu, harga, ketersediaan, dan perilaku stok.',
            action: FilledButton.icon(
              onPressed: () => _openProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            ),
          ),
          SizedBox(height: roleTokens.sectionGap),
          Expanded(
            child: catalog.when(
              loading: () =>
                  const AppLoadingState(message: 'Menyiapkan katalog produk…'),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
              ),
              data: (snapshot) {
                if (snapshot.products.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.local_cafe_outlined,
                    title: 'Belum ada produk',
                    message:
                        'Tambahkan produk pertama agar dapat digunakan pada POS.',
                    actionLabel: 'Tambah Produk',
                    onAction: () => _openProductDialog(context),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    if (constraints.maxWidth >= AppLayout.largeBreakpoint &&
                        textScale <= 1.3) {
                      return _ProductLedger(snapshot: snapshot);
                    }
                    return _ProductCards(snapshot: snapshot);
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

class _ProductLedger extends ConsumerWidget {
  const _ProductLedger({required this.snapshot});

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
              DataColumn(label: Text('PRODUK')),
              DataColumn(label: Text('KATEGORI')),
              DataColumn(label: Text('HARGA'), numeric: true),
              DataColumn(label: Text('STOK')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('AKSI')),
            ],
            rows: [
              for (final product in snapshot.products)
                _row(context, ref, product),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, ProductRecord product) {
    final category = snapshot.categoryById[product.categoryId];
    final inventory = snapshot.inventoryByProductId[product.id];
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Icon(
                product.isManualBrew ? Icons.science : Icons.local_cafe,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(product.name),
            ],
          ),
        ),
        DataCell(Text(category?.name ?? '-')),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              MoneyFormatter.format(product.basePrice),
              style: AppTypography.bodyStrong.merge(AppTypography.monetary),
            ),
          ),
        ),
        DataCell(
          Text(
            product.trackInventory
                ? (inventory?.quantity.toString() ?? '-')
                : 'Tidak dilacak',
          ),
        ),
        DataCell(
          AppStatusBadge(
            label: product.isActive ? 'Aktif' : 'Nonaktif',
            status: product.isActive ? AppStatus.success : AppStatus.neutral,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit ${product.name}',
                onPressed: () => _openProductDialog(context, product: product),
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Hapus ${product.name}',
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _deleteProduct(context, ref, product),
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                label: 'Status ${product.name}',
                toggled: product.isActive,
                child: Switch(
                  value: product.isActive,
                  onChanged: (value) => _setProductActive(ref, product, value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCards extends ConsumerWidget {
  const _ProductCards({required this.snapshot});

  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: snapshot.products.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final product = snapshot.products[index];
        final category = snapshot.categoryById[product.categoryId];
        final inventory = snapshot.inventoryByProductId[product.id];

        return AppSectionCard(
          tone: AppSectionTone.plain,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    product.isManualBrew ? Icons.science : Icons.local_cafe,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          category?.name ?? 'Tanpa kategori',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          MoneyFormatter.format(product.basePrice),
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.merge(AppTypography.monetary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AppStatusBadge(
                    label: product.isActive ? 'Aktif' : 'Nonaktif',
                    status: product.isActive
                        ? AppStatus.success
                        : AppStatus.neutral,
                  ),
                  AppStatusBadge(
                    label: product.trackInventory
                        ? 'Stok ${inventory?.quantity ?? '-'}'
                        : 'Stok tidak dilacak',
                    status: product.trackInventory
                        ? AppStatus.info
                        : AppStatus.neutral,
                  ),
                  if (product.isManualBrew)
                    const AppStatusBadge(
                      label: 'Manual Brew',
                      status: AppStatus.info,
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
                  IconButton(
                    tooltip: 'Edit ${product.name}',
                    onPressed: () =>
                        _openProductDialog(context, product: product),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Hapus ${product.name}',
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteProduct(context, ref, product),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  Semantics(
                    label: 'Status ${product.name}',
                    toggled: product.isActive,
                    child: Switch(
                      value: product.isActive,
                      onChanged: (value) =>
                          _setProductActive(ref, product, value),
                    ),
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

Future<void> _openProductDialog(
  BuildContext context, {
  ProductRecord? product,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ProductFormDialog(product: product),
  );
}

Future<void> _deleteProduct(
  BuildContext context,
  WidgetRef ref,
  ProductRecord product,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Produk'),
      content: const Text(
        'Produk dan data stoknya akan dihapus. Tindakan ini tidak dapat dibatalkan.',
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

  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(catalogRepositoryProvider).deleteProduct(product.id);
    ref.invalidate(adminCatalogSnapshotProvider);
    ref.invalidate(catalogSnapshotProvider);
    ref.invalidate(auditLogsProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Produk berhasil dihapus')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

Future<void> _setProductActive(
  WidgetRef ref,
  ProductRecord product,
  bool value,
) async {
  final user = ref.read(authControllerProvider).value?.user;
  await ref
      .read(catalogRepositoryProvider)
      .setProductActive(
        product,
        value,
        actorUserId: user?.id,
        actorUsername: user?.username,
      );
  ref.invalidate(adminCatalogSnapshotProvider);
  ref.invalidate(catalogSnapshotProvider);
  ref.invalidate(auditLogsProvider);
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});

  final ProductRecord? product;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _basePrice;
  late final TextEditingController _hotPrice;
  late final TextEditingController _icePrice;
  late final TextEditingController _initialStock;
  late final TextEditingController _lowStockThreshold;
  String? _categoryId;
  bool _trackInventory = true;
  bool _isManualBrew = false;
  bool _saving = false;
  final Set<String> _selectedAddons = {};
  bool _addonsInitialized = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _basePrice = TextEditingController(
      text: product?.basePrice.toString() ?? '',
    );
    _hotPrice = TextEditingController(
      text: product?.hotPrice?.toString() ?? '',
    );
    _icePrice = TextEditingController(
      text: product?.icePrice?.toString() ?? '',
    );
    _initialStock = TextEditingController(text: '0');
    _lowStockThreshold = TextEditingController(text: '5');
    _categoryId = product?.categoryId;
    _trackInventory = product?.trackInventory ?? true;
    _isManualBrew = product?.isManualBrew ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _basePrice.dispose();
    _hotPrice.dispose();
    _icePrice.dispose();
    _initialStock.dispose();
    _lowStockThreshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(adminCatalogSnapshotProvider);
    final compact = AppLayout.isCompact(MediaQuery.sizeOf(context).width);
    final title = widget.product == null ? 'Tambah Produk' : 'Edit Produk';
    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppLayout.dialogMediumMaxWidth,
      ),
      child: catalog.when(
        loading: () => const AppLoadingState(message: 'Menyiapkan kategori…'),
        error: (error, _) => AppErrorState(
          message: ErrorMessage.from(error),
          onRetry: () => ref.invalidate(adminCatalogSnapshotProvider),
        ),
        data: (snapshot) {
          if (!_addonsInitialized && widget.product != null) {
            final existingAddons = snapshot.productAddons
                .where((row) => row.productId == widget.product!.id)
                .map((row) => row.addonId);
            _selectedAddons.addAll(existingAddons);
            _addonsInitialized = true;
          } else if (!_addonsInitialized) {
            _addonsInitialized = true;
          }

          final categories = snapshot.categories
              .where(
                (category) =>
                    category.parentId != null &&
                    (category.isActive ||
                        category.id == widget.product?.categoryId),
              )
              .toList();
          _categoryId ??= categories.isEmpty ? null : categories.first.id;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                tone: AppSectionTone.plain,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Identitas menu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nama produk',
                      ),
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppDropdownField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                      enabled: !_saving,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionCard(
                tone: AppSectionTone.warm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Harga',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _basePrice,
                      decoration: const InputDecoration(
                        labelText: 'Harga dasar',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _hotPrice,
                      decoration: const InputDecoration(
                        labelText: 'Harga Panas',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _icePrice,
                      decoration: const InputDecoration(
                        labelText: 'Harga Dingin',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_saving,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionCard(
                tone: AppSectionTone.lake,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Operasional',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SwitchListTile(
                      contentPadding: AppSpacing.zero,
                      value: _trackInventory,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _trackInventory = value),
                      title: const Text('Lacak stok produk'),
                    ),
                    if (_trackInventory && widget.product == null) ...[
                      TextField(
                        controller: _initialStock,
                        decoration: const InputDecoration(
                          labelText: 'Stok awal',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _lowStockThreshold,
                        decoration: const InputDecoration(
                          labelText: 'Batas minimum stok',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: AppSpacing.zero,
                      value: _isManualBrew,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _isManualBrew = value),
                      title: const Text('Produk Manual Brew'),
                    ),
                  ],
                ),
              ),
              if (snapshot.addons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppSectionCard(
                  tone: AppSectionTone.plain,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pilihan tambahan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final addon in snapshot.addons)
                            FilterChip(
                              label: Text(addon.name),
                              selected: _selectedAddons.contains(addon.id),
                              onSelected: _saving
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedAddons.add(addon.id);
                                        } else {
                                          _selectedAddons.remove(addon.id);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
    final messenger = ScaffoldMessenger.of(context);
    final categoryId = _categoryId;
    if (categoryId == null || _name.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nama produk dan kategori wajib diisi')),
      );
      return;
    }
    final basePrice = int.tryParse(_basePrice.text.trim());
    final hotPrice = _hotPrice.text.trim().isEmpty
        ? null
        : int.tryParse(_hotPrice.text.trim());
    final icePrice = _icePrice.text.trim().isEmpty
        ? null
        : int.tryParse(_icePrice.text.trim());
    final initialStock = int.tryParse(_initialStock.text.trim());
    final lowStockThreshold = int.tryParse(_lowStockThreshold.text.trim());
    final invalidOptionalPrice =
        (_hotPrice.text.trim().isNotEmpty && hotPrice == null) ||
        (_icePrice.text.trim().isNotEmpty && icePrice == null);
    if (basePrice == null ||
        invalidOptionalPrice ||
        initialStock == null ||
        lowStockThreshold == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Harga dan stok harus berupa angka yang valid'),
        ),
      );
      return;
    }
    final user = ref.read(authControllerProvider).value?.user;
    setState(() => _saving = true);
    try {
      final productId = widget.product?.id ?? IdGenerator.create();
      await ref
          .read(catalogRepositoryProvider)
          .saveProduct(
            id: productId,
            name: _name.text,
            categoryId: categoryId,
            basePrice: basePrice,
            hotPrice: hotPrice,
            icePrice: icePrice,
            isActive: widget.product?.isActive ?? true,
            trackInventory: _trackInventory,
            isManualBrew: _isManualBrew,
            initialStock: initialStock,
            lowStockThreshold: lowStockThreshold,
            actorUserId: user?.id,
            actorUsername: user?.username,
          );
      await ref
          .read(catalogRepositoryProvider)
          .updateProductAddons(productId, _selectedAddons.toList());
      ref.invalidate(adminCatalogSnapshotProvider);
      ref.invalidate(catalogSnapshotProvider);
      ref.invalidate(auditLogsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
