/// Domain contract for CatalogRepository. Concrete implementation in data layer.
library;

import '../../data/database/app_database.dart';

// ---------------------------------------------------------------------------
// CatalogSnapshot – value object shared between domain and data layers.
// ---------------------------------------------------------------------------

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.categories,
    required this.products,
    required this.addons,
    required this.productAddons,
    required this.beans,
    required this.methods,
    required this.inventory,
  });

  final List<CategoryRecord> categories;
  final List<ProductRecord> products;
  final List<AddonRecord> addons;
  final List<ProductAddonRecord> productAddons;
  final List<BeanRecord> beans;
  final List<ManualBrewMethodRecord> methods;
  final List<InventoryRecord> inventory;

  Map<String, CategoryRecord> get categoryById => {
    for (final category in categories) category.id: category,
  };

  Map<String, InventoryRecord> get inventoryByProductId => {
    for (final row in inventory) row.productId: row,
  };

  List<InventoryRecord> get trackedInventory {
    final trackedProductIds = products
        .where((product) => product.trackInventory)
        .map((product) => product.id)
        .toSet();
    return inventory
        .where((row) => trackedProductIds.contains(row.productId))
        .toList();
  }

  List<InventoryRecord> get lowStockInventory {
    final productById = {for (final product in products) product.id: product};
    final rows = inventory.where((row) {
      final product = productById[row.productId];
      return product != null &&
          product.isActive &&
          product.trackInventory &&
          row.quantity <= row.lowStockThreshold;
    }).toList();
    rows.sort(
      (a, b) => (a.quantity - a.lowStockThreshold).compareTo(
        b.quantity - b.lowStockThreshold,
      ),
    );
    return rows;
  }

  List<CategoryRecord> rootCategories(String type) => categories
      .where((category) => category.parentId == null && category.type == type)
      .toList();

  List<CategoryRecord> childrenOf(String parentId) => categories
      .where((category) => category.parentId == parentId && category.isActive)
      .toList();

  List<ProductRecord> productsForCategory(String categoryId) => products
      .where((product) => product.categoryId == categoryId && product.isActive)
      .toList();

  List<AddonRecord> addonsForProduct(String productId) {
    final addonIds = productAddons
        .where((row) => row.productId == productId)
        .map((row) => row.addonId)
        .toSet();
    return addons
        .where((addon) => addonIds.contains(addon.id) && addon.isActive)
        .toList();
  }

  CategoryRecord? categoryForProduct(ProductRecord product) {
    return categoryById[product.categoryId];
  }
}

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

abstract class CatalogRepositoryContract {
  Future<CatalogSnapshot> snapshot({bool activeOnly = true});

  Future<List<CategoryRecord>> allCategories();

  Future<List<ProductRecord>> allProducts();

  Future<List<AddonRecord>> allAddons();

  Future<List<BeanRecord>> allBeans();

  Future<List<ManualBrewMethodRecord>> allMethods();

  Future<List<InventoryRecord>> inventory();

  Stream<Set<String>> watchFavoriteProductIds(String userId);

  Future<void> setProductFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  });

  Future<List<StockMovementRecord>> stockMovementsForProduct(String productId);

  Future<void> deleteProduct(String id);

  Future<void> deleteCategory(String id);

  Future<void> deleteAddon(String id);

  Future<void> deleteBean(String id);

  Future<void> deleteMethod(String id);

  Future<void> saveProduct({
    String? id,
    required String name,
    required String categoryId,
    required int basePrice,
    int? hotPrice,
    int? icePrice,
    bool isActive = true,
    bool trackInventory = true,
    bool isManualBrew = false,
    int initialStock = 0,
    int lowStockThreshold = 5,
    String? actorUserId,
    String? actorUsername,
  });

  Future<void> updateProductAddons(String productId, List<String> addonIds);

  Future<void> setProductActive(
    ProductRecord product,
    bool active, {
    String? actorUserId,
    String? actorUsername,
  });

  Future<void> saveCategory({
    String? id,
    required String name,
    required String type,
    String? parentId,
    bool isActive = true,
    int? sortOrder,
  });

  Future<void> setCategoryActive(CategoryRecord category, bool active);

  Future<void> saveAddon({
    String? id,
    required String name,
    required int price,
    bool isActive = true,
  });

  Future<void> saveBean({
    String? id,
    required String name,
    required int hotPrice,
    required int icePrice,
    bool isActive = true,
  });

  Future<void> saveMethod({
    String? id,
    required String name,
    bool isActive = true,
  });

  Future<void> updateInventory(String productId, int quantity);

  Future<void> adjustInventory({
    required String productId,
    required int quantityAfter,
    required String type,
    int? lowStockThreshold,
    String? notes,
    String? actorUserId,
    String? actorUsername,
  });
}
