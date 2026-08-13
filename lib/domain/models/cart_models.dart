import '../../core/utils/id_generator.dart';

const Object _cartItemUnset = Object();

class CartAddon {
  const CartAddon({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final int price;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'price': price};
}

class CartItem {
  CartItem({
    String? lineId,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.unitPrice,
    required this.quantity,
    this.temperatureOption,
    this.sugarOption,
    this.manualBrewMethodId,
    this.manualBrewMethodName,
    this.beanId,
    this.beanName,
    this.addons = const [],
    this.notes,
    this.trackInventory = false,
  }) : lineId = lineId ?? IdGenerator.create();

  final String lineId;
  final String productId;
  final String productName;
  final String categoryName;
  final int unitPrice;
  final int quantity;
  final String? temperatureOption;
  final String? sugarOption;
  final String? manualBrewMethodId;
  final String? manualBrewMethodName;
  final String? beanId;
  final String? beanName;
  final List<CartAddon> addons;
  final String? notes;
  final bool trackInventory;

  int get addonsTotal => addons.fold(0, (sum, addon) => sum + addon.price);
  int get effectiveUnitPrice => unitPrice + addonsTotal;
  int get subtotal => effectiveUnitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    Object? unitPrice = _cartItemUnset,
    Object? temperatureOption = _cartItemUnset,
    Object? sugarOption = _cartItemUnset,
    Object? notes = _cartItemUnset,
  }) {
    return CartItem(
      lineId: lineId,
      productId: productId,
      productName: productName,
      categoryName: categoryName,
      unitPrice: unitPrice == _cartItemUnset
          ? this.unitPrice
          : unitPrice as int,
      quantity: quantity ?? this.quantity,
      temperatureOption: temperatureOption == _cartItemUnset
          ? this.temperatureOption
          : temperatureOption as String?,
      sugarOption: sugarOption == _cartItemUnset
          ? this.sugarOption
          : sugarOption as String?,
      manualBrewMethodId: manualBrewMethodId,
      manualBrewMethodName: manualBrewMethodName,
      beanId: beanId,
      beanName: beanName,
      addons: addons,
      notes: notes == _cartItemUnset ? this.notes : notes as String?,
      trackInventory: trackInventory,
    );
  }
}

class CartState {
  const CartState({this.items = const []});

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  int get total => subtotal;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}
