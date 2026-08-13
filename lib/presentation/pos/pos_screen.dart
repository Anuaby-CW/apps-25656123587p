import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/idr_amount_input_formatter.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../domain/models/cart_models.dart';
import '../../domain/models/enums.dart';
import '../../widgets/common/app_alert.dart';
import '../../core/routing/app_destination.dart';
import '../../domain/usecases/manual_brew_pricing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../../widgets/common/app_dropdown_field.dart';
import '../cart/cart_panel.dart';
import '../providers/app_providers.dart';
import '../widgets/async_state_view.dart';

// Removed _CatalogMode enum

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _type = 'drink';
  String? _subcategoryId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value?.user;
    final shiftVal = ref.watch(shiftControllerProvider);
    return shiftVal.when(
      loading: () => const _CenteredPosState(
        child: AppLoadingState(message: 'Memuat status shift…'),
      ),
      error: (err, _) => _CenteredPosState(
        child: AppErrorState(
          title: 'Status shift belum dapat dimuat',
          message: 'Periksa kembali status shift sebelum menerima transaksi.',
          onRetry: () => ref.invalidate(shiftControllerProvider),
        ),
      ),
      data: (shift) {
        final role = user != null
            ? UserRole.fromDb(user.role)
            : UserRole.cashier;
        if (role == UserRole.cashier) {
          if (!shift.isActive) {
            return _PosAccessState(
              icon: Icons.lock_clock_outlined,
              title: 'Shift belum aktif',
              message:
                  'Buka shift dari Pengaturan sebelum mulai menerima transaksi.',
              actionLabel: 'Buka Pengaturan Shift',
              actionIcon: Icons.settings_outlined,
              onAction: () => ref
                  .read(selectedDestinationProvider.notifier)
                  .select(AppDestination.settings),
            );
          }
          if (shift.cashierId != user?.id) {
            return _PosAccessState(
              icon: Icons.lock_person_outlined,
              title: 'POS sedang dipakai shift lain',
              message:
                  'Shift aktif dimiliki oleh ${shift.cashierName ?? 'kasir lain'}. Masuk dengan akun tersebut untuk melanjutkan atau menutup shift.',
              actionLabel: 'Keluar & Ganti Kasir',
              actionIcon: Icons.switch_account_outlined,
              danger: true,
              onAction: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            );
          }
        }

        final catalog = ref.watch(catalogSnapshotProvider);
        return AsyncStateView(
          value: catalog,
          onRetry: () => ref.invalidate(catalogSnapshotProvider),
          data: (snapshot) {
            final root = snapshot.rootCategories(_type).firstOrNull;
            final subcategories = root == null
                ? <CategoryRecord>[]
                : snapshot.childrenOf(root.id);
            final selectedSubcategory =
                subcategories.any((category) => category.id == _subcategoryId)
                ? _subcategoryId
                : (subcategories.isEmpty ? null : subcategories.first.id);
            _subcategoryId = selectedSubcategory;

            final products = selectedSubcategory == null
                ? <ProductRecord>[]
                : snapshot.productsForCategory(selectedSubcategory);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDualPane = AppLayout.shouldUseCashierDualPane(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );
                final roleTokens = AppRoleTokens.of(context);
                final catalogView = _CatalogView(
                  snapshot: snapshot,
                  type: _type,
                  subcategories: subcategories,
                  selectedSubcategoryId: selectedSubcategory,
                  products: products,
                  onTypeChanged: (type) => setState(() {
                    _type = type;
                    _subcategoryId = null;
                  }),
                  onSubcategoryChanged: (id) =>
                      setState(() => _subcategoryId = id),
                );

                if (isDualPane) {
                  return Padding(
                    padding: EdgeInsets.all(
                      roleTokens.pagePaddingFor(constraints.maxWidth),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: catalogView,
                            ),
                          ),
                        ),
                        SizedBox(width: roleTokens.sectionGap),
                        const SizedBox(
                          width: AppLayout.cashierCartWidth,
                          child: CartPanel(),
                        ),
                      ],
                    ),
                  );
                }

                return _MobilePosLayout(catalogView: catalogView);
              },
            );
          },
        );
      },
    );
  }
}

class _CenteredPosState extends StatelessWidget {
  const _CenteredPosState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.allLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.dialogSmallMaxWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PosAccessState extends StatelessWidget {
  const _PosAccessState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _CenteredPosState(
      child: AppSectionCard(
        tone: danger ? AppSectionTone.attention : AppSectionTone.lake,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: danger ? scheme.errorContainer : scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: AppSpacing.allSm,
                child: Icon(
                  icon,
                  size: AppLayout.cashierSecondaryControlHeight,
                  color: danger
                      ? scheme.onErrorContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: AppLayout.cashierControlHeight,
              child: FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilePosLayout extends ConsumerWidget {
  const _MobilePosLayout({required this.catalogView});

  final Widget catalogView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = ref.watch(
      cartControllerProvider.select((cart) => !cart.isEmpty),
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final catalogBottomPadding = hasItems
        ? AppLayout.cashierBottomDockHeight + AppSpacing.sm + bottomInset
        : AppSpacing.none;

    return Padding(
      padding: AppSpacing.allSm,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedPadding(
                duration: AppMotion.emphasis,
                curve: AppMotion.curve,
                padding: EdgeInsets.only(bottom: catalogBottomPadding),
                child: catalogView,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset,
              child: const _FloatingCartBar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCartBar extends ConsumerWidget {
  const _FloatingCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final hasItems = !cart.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      ignoring: !hasItems,
      child: AnimatedSlide(
        duration: AppMotion.emphasis,
        curve: AppMotion.curve,
        offset: hasItems ? Offset.zero : const Offset(0, 1.25),
        child: AnimatedOpacity(
          duration: AppMotion.standard,
          opacity: hasItems ? 1 : 0,
          child: AnimatedScale(
            duration: AppMotion.emphasis,
            curve: AppMotion.curve,
            scale: hasItems ? 1 : 0.98,
            child: Semantics(
              button: true,
              label:
                  'Buka keranjang, ${cart.itemCount} produk, total ${MoneyFormatter.format(cart.total)}',
              child: SizedBox(
                height: AppLayout.cashierBottomDockHeight,
                child: Material(
                  color: colorScheme.primary,
                  borderRadius: AppRadius.dock,
                  elevation: AppShadows.floatingElevation,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showCartSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${cart.itemCount} produk',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Text(
                            MoneyFormatter.format(cart.total),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height - AppSpacing.hero;
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return AnimatedPadding(
          duration: AppMotion.standard,
          curve: AppMotion.curve,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: height,
            child: const Padding(
              padding: AppSpacing.allSm,
              child: CartPanel(compact: true),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogView extends ConsumerWidget {
  const _CatalogView({
    required this.snapshot,
    required this.type,
    required this.subcategories,
    required this.selectedSubcategoryId,
    required this.products,
    required this.onTypeChanged,
    required this.onSubcategoryChanged,
  });

  final CatalogSnapshot snapshot;
  final String type;
  final List<CategoryRecord> subcategories;
  final String? selectedSubcategoryId;
  final List<ProductRecord> products;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSubcategoryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MENU', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppLayout.cashierControlHeight,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'drink',
                icon: Icon(Icons.local_cafe_outlined),
                label: Text('Minuman'),
              ),
              ButtonSegment(
                value: 'food',
                icon: Icon(Icons.restaurant_outlined),
                label: Text('Makanan'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (value) => onTypeChanged(value.first),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppLayout.cashierControlHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subcategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final category = subcategories[index];
              return ChoiceChip(
                label: Text(category.name),
                selected: selectedSubcategoryId == category.id,
                onSelected: (_) => onSubcategoryChanged(category.id),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: products.isEmpty
              ? const AppEmptyState(
                  title: 'Produk kosong',
                  message:
                      'Produk untuk kategori ini akan tampil di papan menu.',
                  icon: Icons.inventory_2_outlined,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final bodyScale = MediaQuery.textScalerOf(
                      context,
                    ).scale(AppSpacing.md);
                    final textScaleAllowance = (bodyScale - AppSpacing.md)
                        .clamp(AppSpacing.none, AppSpacing.section);

                    final crossAxisCount =
                        ((constraints.maxWidth + AppSpacing.sm) /
                                (AppLayout.cashierProductCardMinWidth +
                                    AppSpacing.sm))
                            .floor()
                            .clamp(1, AppLayout.cashierProductCardMaxColumns);

                    return GridView.builder(
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent:
                            (AppLayout.cashierControlHeight * 3.75) +
                            textScaleAllowance,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final category = snapshot.categoryForProduct(product);
                        return _ProductCard(
                          product: product,
                          category: category,
                          snapshot: snapshot,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    required this.category,
    required this.snapshot,
  });

  final ProductRecord product;
  final CategoryRecord? category;
  final CatalogSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = snapshot.inventoryByProductId[product.id];
    final price = product.isManualBrew
        ? 'Pilih biji kopi'
        : MoneyFormatter.format(product.hotPrice ?? product.basePrice);
    final isFood = category?.type == 'food';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isFood ? scheme.tertiary : scheme.primary;
    final accentContainer = isFood
        ? scheme.tertiaryContainer
        : scheme.primaryContainer;
    final onAccentContainer = isFood
        ? scheme.onTertiaryContainer
        : scheme.onPrimaryContainer;

    return Semantics(
      button: true,
      label: 'Pilih ${product.name}, $price',
      child: PosMicroBounce(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _ProductOptionsDialog(
            product: product,
            category: category,
            snapshot: snapshot,
          ),
        ),
        child: Card(
          margin: AppSpacing.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.asymmetricCard,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.asymmetricCard,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accentContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: AppSpacing.allSm,
                          child: Icon(
                            isFood
                                ? Icons.restaurant_outlined
                                : Icons.local_cafe_outlined,
                            color: onAccentContainer,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_circle,
                        color: accent,
                        semanticLabel: 'Tambah ${product.name}',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    price,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.trackInventory && inventory != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppStatusBadge(
                      label: 'Stok ${inventory.quantity}',
                      icon: inventory.quantity <= inventory.lowStockThreshold
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      status: inventory.quantity <= inventory.lowStockThreshold
                          ? AppStatus.danger
                          : AppStatus.info,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductOptionsDialog extends ConsumerStatefulWidget {
  const _ProductOptionsDialog({
    required this.product,
    required this.category,
    required this.snapshot,
  });

  final ProductRecord product;
  final CategoryRecord? category;
  final CatalogSnapshot snapshot;

  @override
  ConsumerState<_ProductOptionsDialog> createState() =>
      _ProductOptionsDialogState();
}

class _ProductOptionsDialogState extends ConsumerState<_ProductOptionsDialog> {
  String _temperature = 'Hot';
  String _sugar = 'Normal Sugar';
  String? _beanId;
  int _quantity = 1;
  final _notes = TextEditingController();
  final _selectedAddons = <String>{};

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isDrink = widget.category?.type == 'drink';
    final isManualBrew = product.isManualBrew;
    final addons = widget.snapshot.addonsForProduct(product.id);
    final selectedBean = widget.snapshot.beans
        .where((bean) => bean.id == _beanId)
        .firstOrNull;
    final unitPrice = _unitPrice(product, selectedBean, isDrink);

    return AlertDialog(
      title: Text(product.name),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.dialogMediumMaxWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isManualBrew) ...[
                AppDropdownField<String>(
                  initialValue: _beanId,
                  decoration: const InputDecoration(labelText: 'Biji Kopi'),
                  items: [
                    for (final bean in widget.snapshot.beans)
                      DropdownMenuItem(
                        value: bean.id,
                        child: Text(
                          '${bean.name} — Panas ${MoneyFormatter.format(bean.hotPrice)} / Dingin ${MoneyFormatter.format(bean.icePrice)}',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _beanId = value),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (isDrink) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Hot',
                      icon: Icon(Icons.local_fire_department_outlined),
                      label: Text('Panas'),
                    ),
                    ButtonSegment(
                      value: 'Ice',
                      icon: Icon(Icons.ac_unit_outlined),
                      label: Text('Dingin'),
                    ),
                  ],
                  selected: {_temperature},
                  onSelectionChanged: (value) =>
                      setState(() => _temperature = value.first),
                ),
                if (!isManualBrew) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final option in const [
                        ('No Sugar', 'No sugar'),
                        ('Less Sugar', 'Less'),
                        ('Normal Sugar', 'Normal'),
                      ])
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppLayout.cashierSecondaryControlHeight,
                          ),
                          child: ChoiceChip(
                            label: Text(option.$2),
                            selected: _sugar == option.$1,
                            onSelected: (_) =>
                                setState(() => _sugar = option.$1),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
              if (addons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final addon in addons)
                      FilterChip(
                        label: Text(
                          '${addon.name} +${MoneyFormatter.format(addon.price)}',
                        ),
                        selected: _selectedAddons.contains(addon.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedAddons.add(addon.id);
                          } else {
                            _selectedAddons.remove(addon.id);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: AppLayout.cashierSecondaryControlHeight,
                        child: IconButton.filledTonal(
                          onPressed: _quantity <= 1
                              ? null
                              : () => setState(() => _quantity--),
                          icon: const Icon(Icons.remove),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox.square(
                        dimension: AppLayout.cashierSecondaryControlHeight,
                        child: IconButton.filledTonal(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    MoneyFormatter.format(unitPrice * _quantity),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Catatan pesanan',
                  hintText: 'Contoh: sajikan terpisah',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        SizedBox(
          height: AppLayout.cashierControlHeight,
          child: FilledButton.icon(
            onPressed: () => _addToCart(unitPrice),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              'Tambah • ${MoneyFormatter.format(unitPrice * _quantity)}',
            ),
          ),
        ),
      ],
    );
  }

  int _unitPrice(ProductRecord product, BeanRecord? bean, bool isDrink) {
    if (product.isManualBrew) {
      if (bean == null) {
        return 0;
      }
      return ManualBrewPricing.priceForBean(
        hotPrice: bean.hotPrice,
        icePrice: bean.icePrice,
        temperature: _temperature,
      );
    }
    if (isDrink) {
      return _temperature == 'Hot'
          ? (product.hotPrice ?? product.basePrice)
          : (product.icePrice ?? product.basePrice);
    }
    return product.basePrice;
  }

  void _addToCart(int unitPrice) {
    final product = widget.product;
    final isDrink = widget.category?.type == 'drink';
    String? manualBrewMethodId;
    String? manualBrewMethodName;
    BeanRecord? bean;
    if (product.isManualBrew) {
      bean = widget.snapshot.beans
          .where((row) => row.id == _beanId)
          .firstOrNull;
      if (bean == null || unitPrice <= 0) {
        AppAlert.show(
          context,
          'Manual Brew wajib memilih biji kopi serta suhu Panas atau Dingin.',
          type: AppAlertType.error,
        );
        return;
      }
    }

    final settingsValue = ref.read(settingsProvider);
    final inventoryEnabled =
        !settingsValue.hasValue ||
        settingsValue.value?['inventory_enabled'] != 'false';
    if (inventoryEnabled && product.trackInventory) {
      final inventory = widget.snapshot.inventoryByProductId[product.id];
      final currentCartQty = ref
          .read(cartControllerProvider)
          .items
          .where((item) => item.productId == product.id)
          .fold(0, (sum, item) => sum + item.quantity);
      if (inventory == null ||
          inventory.quantity < currentCartQty + _quantity) {
        AppAlert.show(context, 'Stok produk habis', type: AppAlertType.error);
        return;
      }
    }

    final selectedAddons = widget.snapshot.addons
        .where((addon) => _selectedAddons.contains(addon.id))
        .map(
          (addon) =>
              CartAddon(id: addon.id, name: addon.name, price: addon.price),
        )
        .toList();

    ref
        .read(cartControllerProvider.notifier)
        .add(
          CartItem(
            productId: product.id,
            productName: product.name,
            categoryName: widget.category?.name ?? '-',
            unitPrice: unitPrice,
            quantity: _quantity,
            temperatureOption: isDrink ? _temperature : null,
            sugarOption: isDrink && !product.isManualBrew ? _sugar : null,
            manualBrewMethodId: manualBrewMethodId,
            manualBrewMethodName: manualBrewMethodName,
            beanId: bean?.id,
            beanName: bean?.name,
            addons: selectedAddons,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            trackInventory: product.trackInventory,
          ),
        );
    Navigator.of(context).pop();
  }
}

void showPettyCashDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) => const PettyCashDialog(),
  );
}

class PettyCashDialog extends ConsumerStatefulWidget {
  const PettyCashDialog({super.key});

  @override
  ConsumerState<PettyCashDialog> createState() => _PettyCashDialogState();
}

class _PettyCashDialogState extends ConsumerState<PettyCashDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Catat Kas Keluar'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Uang',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [IdrAmountInputFormatter()],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah uang wajib diisi';
                }
                final amt = IdrAmountInputFormatter.parse(value);
                if (amt == null || amt <= 0) {
                  return 'Jumlah uang harus lebih besar dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (Keperluan)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Keterangan wajib diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        SizedBox(
          height: AppLayout.cashierControlHeight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: AppLayout.progressStrokeWidth,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan…' : 'Simpan'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amt =
          IdrAmountInputFormatter.parse(_amountController.text.trim()) ?? 0;
      final notes = _notesController.text.trim();
      await ref
          .read(pettyCashControllerProvider.notifier)
          .addEntry(amount: amt, notes: notes);
      if (mounted) {
        Navigator.of(context).pop();
        AppAlert.show(
          context,
          'Kas keluar berhasil dicatat',
          type: AppAlertType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppAlert.show(
          context,
          'Gagal mencatat kas keluar: $e',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class PosMicroBounce extends StatefulWidget {
  const PosMicroBounce({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PosMicroBounce> createState() => _PosMicroBounceState();
}

class _PosMicroBounceState extends State<PosMicroBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.fast);
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: AppRadius.asymmetricCard,
                canRequestFocus: true,
                onHighlightChanged: (highlighted) {
                  if (disableAnimations) {
                    return;
                  }
                  if (highlighted) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
                onTap: widget.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
