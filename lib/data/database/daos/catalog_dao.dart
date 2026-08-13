import 'package:drift/drift.dart';

import '../app_database.dart';

class CatalogDao {
  CatalogDao(this._db);

  final AppDatabase _db;

  Future<List<CategoryRecord>> categories({bool activeOnly = false}) {
    final query = _db.select(_db.categories)
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.parentId),
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.name),
      ]);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    return query.get();
  }

  Future<List<ProductRecord>> products({bool activeOnly = false}) {
    final query = _db.select(_db.products)
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.name),
      ]);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    return query.get();
  }

  Future<ProductRecord?> productById(String id) {
    return (_db.select(
      _db.products,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<Set<String>> watchFavoriteProductIds(String userId) {
    final query = _db.select(_db.productFavorites)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.productId).toSet(),
    );
  }

  Future<void> setProductFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      await _db
          .into(_db.productFavorites)
          .insert(
            ProductFavoritesCompanion.insert(
              userId: userId,
              productId: productId,
              createdAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return;
    }

    await (_db.delete(_db.productFavorites)..where(
          (tbl) => tbl.userId.equals(userId) & tbl.productId.equals(productId),
        ))
        .go();
  }

  Future<CategoryRecord?> categoryById(String id) {
    return (_db.select(
      _db.categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<AddonRecord>> addons({bool activeOnly = false}) {
    final query = _db.select(_db.addons)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    return query.get();
  }

  Future<List<ProductAddonRecord>> productAddons() {
    return _db.select(_db.productAddons).get();
  }

  Future<List<BeanRecord>> beans({bool activeOnly = false}) {
    final query = _db.select(_db.beans)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    return query.get();
  }

  Future<List<ManualBrewMethodRecord>> methods({bool activeOnly = false}) {
    final query = _db.select(_db.manualBrewMethods)
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.name),
      ]);
    if (activeOnly) {
      query.where((tbl) => tbl.isActive.equals(true));
    }
    return query.get();
  }

  Future<List<InventoryRecord>> inventory() {
    return _db.select(_db.inventory).get();
  }

  Future<InventoryRecord?> inventoryForProduct(String productId) {
    return (_db.select(
      _db.inventory,
    )..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
  }

  Future<List<StockMovementRecord>> stockMovementsForProduct(String productId) {
    return (_db.select(_db.stockMovements)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(50))
        .get();
  }

  Future<bool> hasStockMovementHistory(String productId) async {
    final movement =
        await (_db.select(_db.stockMovements)
              ..where((tbl) => tbl.productId.equals(productId))
              ..limit(1))
            .getSingleOrNull();
    return movement != null;
  }

  Future<void> deleteInventoryForProduct(String productId) {
    return (_db.delete(
      _db.inventory,
    )..where((tbl) => tbl.productId.equals(productId))).go();
  }

  Future<void> deleteProduct(String id) async {
    return _db.transaction(() async {
      final orderItem =
          await (_db.select(_db.orderItems)
                ..where((tbl) => tbl.productId.equals(id))
                ..limit(1))
              .getSingleOrNull();
      final stockMovement =
          await (_db.select(_db.stockMovements)
                ..where((tbl) => tbl.productId.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (orderItem != null || stockMovement != null) {
        throw StateError(
          'Produk memiliki riwayat transaksi atau pergerakan stok dan tidak dapat dihapus. Nonaktifkan produk sebagai gantinya.',
        );
      }

      await (_db.delete(
        _db.productAddons,
      )..where((tbl) => tbl.productId.equals(id))).go();
      await (_db.delete(
        _db.productFavorites,
      )..where((tbl) => tbl.productId.equals(id))).go();
      await (_db.delete(
        _db.inventory,
      )..where((tbl) => tbl.productId.equals(id))).go();
      await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  Future<void> deleteCategory(String id) async {
    final productCount = _db.products.id.count();
    final productsQuery = _db.selectOnly(_db.products)
      ..addColumns([productCount])
      ..where(_db.products.categoryId.equals(id));
    if ((await productsQuery
            .map((row) => row.read(productCount) ?? 0)
            .getSingle()) >
        0) {
      throw StateError(
        'Kategori masih digunakan produk. Pindahkan atau hapus produknya dahulu.',
      );
    }

    final childCount = _db.categories.id.count();
    final childrenQuery = _db.selectOnly(_db.categories)
      ..addColumns([childCount])
      ..where(_db.categories.parentId.equals(id));
    if ((await childrenQuery
            .map((row) => row.read(childCount) ?? 0)
            .getSingle()) >
        0) {
      throw StateError(
        'Kategori masih memiliki subkategori. Hapus subkategori dahulu.',
      );
    }
    await (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAddon(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.productAddons,
      )..where((tbl) => tbl.addonId.equals(id))).go();
      await (_db.delete(_db.addons)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  Future<void> deleteBean(String id) {
    return (_db.delete(_db.beans)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteMethod(String id) {
    return (_db.delete(
      _db.manualBrewMethods,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateProductAddons(
    String productId,
    List<String> addonIds,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.productAddons,
      )..where((tbl) => tbl.productId.equals(productId))).go();
      for (final addonId in addonIds) {
        await _db
            .into(_db.productAddons)
            .insert(
              ProductAddonsCompanion.insert(
                id: '${productId}_$addonId',
                productId: productId,
                addonId: addonId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<void> upsertProduct(ProductsCompanion product) {
    return _db.into(_db.products).insertOnConflictUpdate(product);
  }

  Future<void> updateProduct(String id, ProductsCompanion product) {
    return (_db.update(
      _db.products,
    )..where((tbl) => tbl.id.equals(id))).write(product);
  }

  Future<void> upsertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insertOnConflictUpdate(category);
  }

  Future<void> upsertAddon(AddonsCompanion addon) {
    return _db.into(_db.addons).insertOnConflictUpdate(addon);
  }

  Future<void> upsertBean(BeansCompanion bean) {
    return _db.into(_db.beans).insertOnConflictUpdate(bean);
  }

  Future<void> upsertMethod(ManualBrewMethodsCompanion method) {
    return _db.into(_db.manualBrewMethods).insertOnConflictUpdate(method);
  }

  Future<void> updateInventory(
    String productId,
    int quantity,
    DateTime now, {
    int? lowStockThreshold,
  }) async {
    final existing = await inventoryForProduct(productId);
    if (existing == null) {
      await _db
          .into(_db.inventory)
          .insert(
            InventoryCompanion.insert(
              id: 'inv_$productId',
              productId: productId,
              quantity: Value(quantity),
              lowStockThreshold: Value(lowStockThreshold ?? 5),
              updatedAt: now,
            ),
          );
      return;
    }
    await (_db.update(
      _db.inventory,
    )..where((tbl) => tbl.productId.equals(productId))).write(
      InventoryCompanion(
        quantity: Value(quantity),
        lowStockThreshold: lowStockThreshold == null
            ? const Value.absent()
            : Value(lowStockThreshold),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> ensureInventory({
    required String productId,
    required int quantity,
    required int lowStockThreshold,
    required DateTime now,
  }) async {
    final existing = await inventoryForProduct(productId);
    if (existing != null) {
      return;
    }
    await _db
        .into(_db.inventory)
        .insert(
          InventoryCompanion.insert(
            id: 'inv_$productId',
            productId: productId,
            quantity: Value(quantity),
            lowStockThreshold: Value(lowStockThreshold),
            updatedAt: now,
          ),
        );
  }

  Future<void> insertStockMovement(StockMovementsCompanion movement) {
    return _db.into(_db.stockMovements).insert(movement);
  }

  Future<T> transaction<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }
}
