import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_formatter.dart';
import '../../core/utils/checkout_logger.dart';
import '../../domain/models/checkout_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../domain/models/cart_models.dart';
import '../../domain/usecases/manual_brew_pricing.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../checkout/checkout_dialog.dart';
import '../providers/app_providers.dart';

const _temperatureOptions = ['Hot', 'Ice'];
const _sugarOptions = ['No Sugar', 'Less Sugar', 'Normal Sugar'];

String _temperatureDisplayLabel(String option) =>
    option == 'Hot' ? 'Panas' : 'Dingin';

String _sugarDisplayLabel(String option) => switch (option) {
  'No Sugar' => 'Tanpa Gula',
  'Less Sugar' => 'Sedikit Gula',
  _ => 'Normal',
};

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final user = ref.watch(authControllerProvider).value?.user;
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTA BERJALAN',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      compact ? 'Pesanan saat ini' : 'Rincian transaksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              _CartItemCountBadge(count: cart.itemCount),
              const SizedBox(width: AppSpacing.xs),
              SizedBox.square(
                dimension: AppLayout.cashierSecondaryControlHeight,
                child: IconButton(
                  tooltip: 'Kosongkan nota',
                  onPressed: cart.isEmpty
                      ? null
                      : () => _confirmClearCart(context, ref),
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: cart.isEmpty
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: cart.isEmpty
                ? const AppEmptyState(
                    title: 'Nota masih kosong',
                    message: 'Pilih produk untuk mulai transaksi.',
                    icon: Icons.shopping_cart_outlined,
                  )
                : ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(
                        key: ValueKey(item.lineId),
                        item: item,
                      );
                    },
                  ),
          ),
          const Divider(),
          Row(
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                MoneyFormatter.format(cart.total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppLayout.cashierControlHeight,
            child: FilledButton.icon(
              onPressed: cart.isEmpty || user == null
                  ? null
                  : () async {
                      final result = await showDialog<CheckoutResult>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CheckoutDialog(user: user),
                      );
                      if (!context.mounted || result == null) return;
                      if (compact) {
                        Navigator.of(context).pop();
                      }
                      CheckoutLogger.event(
                        CheckoutLogStep.navigationFinished,
                        reference:
                            result.transactionNumber ?? result.orderNumber,
                      );
                    },
              icon: const Icon(Icons.payments),
              label: Text('Bayar • ${MoneyFormatter.format(cart.total)}'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Kosongkan Nota?'),
      content: const Text(
        'Semua produk dan catatan pada transaksi berjalan akan dihapus.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Kosongkan'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref.read(cartControllerProvider.notifier).clear();
  }
}

class _CartItemTile extends ConsumerStatefulWidget {
  const _CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  late final TextEditingController _notesController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextNotes = widget.item.notes ?? '';
    if (_notesController.text != nextNotes) {
      _notesController.value = TextEditingValue(
        text: nextNotes,
        selection: TextSelection.collapsed(offset: nextNotes.length),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final controller = ref.read(cartControllerProvider.notifier);
    final catalogSnapshot = ref.watch(catalogSnapshotProvider).asData?.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: AppRadius.input,
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppLayout.cashierSecondaryControlHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _description(item),
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (item.addons.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Wrap(
                              spacing: AppSpacing.xxs,
                              runSpacing: AppSpacing.xxs,
                              children: [
                                for (final addon in item.addons)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                      borderRadius: AppRadius.badge,
                                    ),
                                    child: Text(
                                      '+${addon.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(MoneyFormatter.format(item.subtotal)),
                        AnimatedRotation(
                          duration: AppMotion.standard,
                          turns: _expanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              SizedBox.square(
                dimension: AppLayout.cashierSecondaryControlHeight,
                child: IconButton.filledTonal(
                  tooltip: 'Kurangi jumlah',
                  onPressed: item.quantity <= 1
                      ? null
                      : () => controller.updateQuantity(
                          item.lineId,
                          item.quantity - 1,
                        ),
                  icon: const Icon(Icons.remove),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  item.quantity.toString(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox.square(
                dimension: AppLayout.cashierSecondaryControlHeight,
                child: IconButton.filledTonal(
                  tooltip: 'Tambah jumlah',
                  onPressed: () =>
                      controller.updateQuantity(item.lineId, item.quantity + 1),
                  icon: const Icon(Icons.add),
                ),
              ),
              const Spacer(),
              SizedBox.square(
                dimension: AppLayout.cashierSecondaryControlHeight,
                child: IconButton(
                  tooltip: 'Hapus produk',
                  onPressed: () => controller.remove(item.lineId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: AppMotion.standard,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _InlineCartOptions(
              item: item,
              notesController: _notesController,
              onTemperatureSelected: (temperature) {
                final unitPrice = _unitPriceForTemperature(
                  item,
                  catalogSnapshot,
                  temperature,
                );
                controller.updateTemperatureOption(
                  item.lineId,
                  temperature,
                  unitPrice: unitPrice,
                );
              },
              onSugarSelected: (sugar) =>
                  controller.updateSugarOption(item.lineId, sugar),
              onNotesChanged: (notes) =>
                  controller.updateNotes(item.lineId, notes),
            ),
          ),
        ],
      ),
    );
  }

  int _unitPriceForTemperature(
    CartItem item,
    CatalogSnapshot? snapshot,
    String temperature,
  ) {
    if (snapshot == null) {
      return item.unitPrice;
    }

    final product = snapshot.products
        .where((product) => product.id == item.productId)
        .firstOrNull;
    if (product == null) {
      return item.unitPrice;
    }

    if (product.isManualBrew) {
      final bean = snapshot.beans
          .where((bean) => bean.id == item.beanId)
          .firstOrNull;
      return bean == null
          ? item.unitPrice
          : ManualBrewPricing.priceForBean(
              hotPrice: bean.hotPrice,
              icePrice: bean.icePrice,
              temperature: temperature,
            );
    }

    final category = snapshot.categoryById[product.categoryId];
    if (category?.type != 'drink') {
      return item.unitPrice;
    }

    return temperature == 'Hot'
        ? (product.hotPrice ?? product.basePrice)
        : (product.icePrice ?? product.basePrice);
  }

  String _description(CartItem item) {
    final parts = [
      item.categoryName,
      item.temperatureOption,
      item.sugarOption == null ? null : _sugarDisplayLabel(item.sugarOption!),
      item.manualBrewMethodName,
      item.beanName,
      item.notes,
    ].where((value) => value != null && value.trim().isNotEmpty);
    return parts.join(' / ');
  }
}

class _InlineCartOptions extends StatelessWidget {
  const _InlineCartOptions({
    required this.item,
    required this.notesController,
    required this.onTemperatureSelected,
    required this.onSugarSelected,
    required this.onNotesChanged,
  });

  final CartItem item;
  final TextEditingController notesController;
  final ValueChanged<String> onTemperatureSelected;
  final ValueChanged<String> onSugarSelected;
  final ValueChanged<String> onNotesChanged;

  @override
  Widget build(BuildContext context) {
    final showTemperature = item.temperatureOption != null;
    final showSugar = item.sugarOption != null;
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTemperature) ...[
            Text('Suhu', style: labelStyle),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final option in _temperatureOptions)
                  FilterChip(
                    label: Text(_temperatureDisplayLabel(option)),
                    selected: item.temperatureOption == option,
                    onSelected: (_) => onTemperatureSelected(option),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (showSugar) ...[
            Text('Takaran gula', style: labelStyle),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final option in _sugarOptions)
                  FilterChip(
                    label: Text(_sugarDisplayLabel(option)),
                    selected: item.sugarOption == option,
                    onSelected: (_) => onSugarSelected(option),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextField(
            controller: notesController,
            minLines: 1,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Catatan produk',
              hintText: 'Contoh: es sedikit, tanpa topping',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            onChanged: onNotesChanged,
          ),
        ],
      ),
    );
  }
}

class _CartItemCountBadge extends StatefulWidget {
  const _CartItemCountBadge({required this.count});
  final int count;

  @override
  State<_CartItemCountBadge> createState() => _CartItemCountBadgeState();
}

class _CartItemCountBadgeState extends State<_CartItemCountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _CartItemCountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        child: Text(
          '${widget.count} produk',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
