import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/repositories/catalog_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/catalog_dao.dart';
import 'audit_repository.dart';

export '../../domain/repositories/catalog_repository_contract.dart'
    show CatalogSnapshot;

class CatalogRepository implements CatalogRepositoryContract {
  CatalogRepository(this._dao, {AuditRepository? auditRepository})
    : _auditRepository = auditRepository;

  final CatalogDao _dao;
  final AuditRepository? _auditRepository;

  @override
  Future<CatalogSnapshot> snapshot({bool activeOnly = true}) async {
    final categories = await _dao.categories(activeOnly: activeOnly);
    final products = await _dao.products(activeOnly: activeOnly);
    final addons = await _dao.addons(activeOnly: activeOnly);
    final productAddons = await _dao.productAddons();
    final beans = await _dao.beans(activeOnly: activeOnly);
    final methods = await _dao.methods(activeOnly: activeOnly);
    final inventory = await _dao.inventory();
    return CatalogSnapshot(
      categories: categories,
      products: products,
      addons: addons,
      productAddons: productAddons,
      beans: beans,
      methods: methods,
      inventory: inventory,
    );
  }

  @override
  Future<List<CategoryRecord>> allCategories() => _dao.categories();
  @override
  Future<List<ProductRecord>> allProducts() => _dao.products();
  @override
  Future<List<AddonRecord>> allAddons() => _dao.addons();
  @override
  Future<List<BeanRecord>> allBeans() => _dao.beans();
  @override
  Future<List<ManualBrewMethodRecord>> allMethods() => _dao.methods();
  @override
  Future<List<InventoryRecord>> inventory() => _dao.inventory();

  @override
  Stream<Set<String>> watchFavoriteProductIds(String userId) {
    return _dao.watchFavoriteProductIds(userId);
  }

  @override
  Future<void> setProductFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  }) {
    return _dao.setProductFavorite(
      userId: userId,
      productId: productId,
      isFavorite: isFavorite,
    );
  }

  @override
  Future<List<StockMovementRecord>> stockMovementsForProduct(String productId) {
    return _dao.stockMovementsForProduct(productId);
  }

  @override
  Future<void> deleteProduct(String id) => _dao.deleteProduct(id);
  @override
  Future<void> deleteCategory(String id) => _dao.deleteCategory(id);
  @override
  Future<void> deleteAddon(String id) => _dao.deleteAddon(id);
  @override
  Future<void> deleteBean(String id) => _dao.deleteBean(id);
  @override
  Future<void> deleteMethod(String id) => _dao.deleteMethod(id);

  @override
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
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Nama produk wajib diisi');
    }
    if (basePrice < 0 || (hotPrice ?? 0) < 0 || (icePrice ?? 0) < 0) {
      throw StateError('Harga produk tidak boleh negatif');
    }
    if (initialStock < 0) {
      throw StateError('Stok awal tidak boleh negatif');
    }
    if (lowStockThreshold < 0) {
      throw StateError('Batas minimum stok tidak boleh negatif');
    }

    final category = await _dao.categoryById(categoryId);
    if (category == null) {
      throw StateError('Kategori produk tidak ditemukan');
    }
    if (!category.isActive && isActive) {
      throw StateError('Produk aktif harus memakai kategori aktif');
    }

    final now = DateTime.now();
    final existing = id == null ? null : await _dao.productById(id);
    final productId = existing?.id ?? id ?? IdGenerator.create();

    await _dao.transaction(() async {
      if (existing == null) {
        await _dao.upsertProduct(
          ProductsCompanion.insert(
            id: productId,
            name: trimmedName,
            categoryId: categoryId,
            basePrice: basePrice,
            hotPrice: Value(hotPrice),
            icePrice: Value(icePrice),
            isActive: Value(isActive),
            trackInventory: Value(trackInventory),
            isManualBrew: Value(isManualBrew),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await _dao.updateProduct(
          productId,
          ProductsCompanion(
            name: Value(trimmedName),
            categoryId: Value(categoryId),
            basePrice: Value(basePrice),
            hotPrice: Value(hotPrice),
            icePrice: Value(icePrice),
            isActive: Value(isActive),
            trackInventory: Value(trackInventory),
            isManualBrew: Value(isManualBrew),
            updatedAt: Value(now),
          ),
        );
      }

      if (trackInventory) {
        await _dao.ensureInventory(
          productId: productId,
          quantity: existing == null ? initialStock : 0,
          lowStockThreshold: lowStockThreshold,
          now: now,
        );
        if (existing == null && initialStock > 0) {
          await _dao.insertStockMovement(
            StockMovementsCompanion.insert(
              id: IdGenerator.create(),
              productId: productId,
              type: 'initial_stock',
              quantityChange: initialStock,
              quantityAfter: initialStock,
              referenceId: Value(productId),
              notes: const Value('Stok awal produk'),
              createdAt: now,
            ),
          );
        }
      } else if (!await _dao.hasStockMovementHistory(productId)) {
        // A never-used inventory row carries no history worth preserving.
        // Once movements exist, retain the current row so re-enabling stock
        // tracking can safely resume from its last known quantity.
        await _dao.deleteInventoryForProduct(productId);
      }
    });

    await _auditRepository?.record(
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: existing == null ? 'product.create' : 'product.update',
      entityType: 'product',
      entityId: productId,
      description: existing == null
          ? 'Produk $trimmedName dibuat'
          : 'Produk $trimmedName diperbarui',
      metadata: {
        'name': trimmedName,
        'categoryId': categoryId,
        'basePrice': basePrice,
        'hotPrice': hotPrice,
        'icePrice': icePrice,
        'isActive': isActive,
        'trackInventory': trackInventory,
        'isManualBrew': isManualBrew,
      },
    );
  }

  @override
  Future<void> setProductActive(
    ProductRecord product,
    bool active, {
    String? actorUserId,
    String? actorUsername,
  }) async {
    await _dao.upsertProduct(
      product
          .copyWith(isActive: active, updatedAt: DateTime.now())
          .toCompanion(true),
    );
    await _auditRepository?.record(
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: active ? 'product.activate' : 'product.deactivate',
      entityType: 'product',
      entityId: product.id,
      description: active
          ? 'Produk ${product.name} diaktifkan'
          : 'Produk ${product.name} dinonaktifkan',
      metadata: {'name': product.name, 'isActive': active},
    );
  }

  @override
  Future<void> updateProductAddons(
    String productId,
    List<String> addonIds,
  ) async {
    if (await _dao.productById(productId) == null) {
      throw StateError('Produk tidak ditemukan');
    }
    final validAddonIds = (await _dao.addons()).map((row) => row.id).toSet();
    final requestedIds = addonIds.toSet();
    if (!validAddonIds.containsAll(requestedIds)) {
      throw StateError('Salah satu add-on tidak ditemukan');
    }
    await _dao.updateProductAddons(productId, requestedIds.toList());
  }

  @override
  Future<void> saveCategory({
    String? id,
    required String name,
    required String type,
    String? parentId,
    bool isActive = true,
    int? sortOrder,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Nama kategori wajib diisi');
    }
    if (type != 'drink' && type != 'food' && type != 'addon') {
      throw StateError('Tipe kategori tidak valid');
    }
    if (parentId == id) {
      throw StateError('Kategori tidak dapat menjadi induk dirinya sendiri');
    }
    if (parentId != null) {
      final parent = await _dao.categoryById(parentId);
      if (parent == null) {
        throw StateError('Kategori induk tidak ditemukan');
      }
      if (parent.type != type) {
        throw StateError('Tipe subkategori harus sama dengan kategori induk');
      }
      if (isActive && !parent.isActive) {
        throw StateError(
          'Kategori aktif tidak dapat menggunakan kategori induk nonaktif',
        );
      }
    }
    final now = DateTime.now();
    await _dao.upsertCategory(
      CategoriesCompanion.insert(
        id: id ?? IdGenerator.create(),
        name: trimmedName,
        type: type,
        parentId: Value(parentId),
        isActive: Value(isActive),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> setCategoryActive(CategoryRecord category, bool active) async {
    if (!active) {
      final activeProducts = (await _dao.products()).where(
        (product) => product.categoryId == category.id && product.isActive,
      );
      final activeChildren = (await _dao.categories()).where(
        (child) => child.parentId == category.id && child.isActive,
      );
      if (activeProducts.isNotEmpty || activeChildren.isNotEmpty) {
        throw StateError(
          'Nonaktifkan produk dan subkategori aktif terlebih dahulu',
        );
      }
    }
    await _dao.upsertCategory(
      category
          .copyWith(isActive: active, updatedAt: DateTime.now())
          .toCompanion(true),
    );
  }

  @override
  Future<void> saveAddon({
    String? id,
    required String name,
    required int price,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Nama add-on wajib diisi');
    }
    if (price < 0) {
      throw StateError('Harga add-on tidak boleh negatif');
    }
    final now = DateTime.now();
    await _dao.upsertAddon(
      AddonsCompanion.insert(
        id: id ?? IdGenerator.create(),
        name: trimmedName,
        price: price,
        isActive: Value(isActive),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> saveBean({
    String? id,
    required String name,
    required int hotPrice,
    required int icePrice,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Nama biji kopi wajib diisi');
    }
    if (hotPrice < 0 || icePrice < 0) {
      throw StateError('Harga biji kopi tidak boleh negatif');
    }
    final now = DateTime.now();
    await _dao.upsertBean(
      BeansCompanion.insert(
        id: id ?? IdGenerator.create(),
        name: trimmedName,
        hotPrice: hotPrice,
        icePrice: icePrice,
        isActive: Value(isActive),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> saveMethod({
    String? id,
    required String name,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Nama metode Manual Brew wajib diisi');
    }
    final now = DateTime.now();
    await _dao.upsertMethod(
      ManualBrewMethodsCompanion.insert(
        id: id ?? IdGenerator.create(),
        name: trimmedName,
        isActive: Value(isActive),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateInventory(String productId, int quantity) {
    return adjustInventory(
      productId: productId,
      quantityAfter: quantity,
      type: 'adjustment',
      notes: 'Pembaruan stok manual',
    );
  }

  @override
  Future<void> adjustInventory({
    required String productId,
    required int quantityAfter,
    required String type,
    int? lowStockThreshold,
    String? notes,
    String? actorUserId,
    String? actorUsername,
  }) async {
    if (quantityAfter < 0) {
      throw StateError('Stok tidak boleh negatif');
    }
    if (lowStockThreshold != null && lowStockThreshold < 0) {
      throw StateError('Batas minimum stok tidak boleh negatif');
    }
    final now = DateTime.now();
    final existing = await _dao.inventoryForProduct(productId);
    final before = existing?.quantity ?? 0;
    final thresholdBefore = existing?.lowStockThreshold ?? 5;
    final thresholdAfter = lowStockThreshold ?? thresholdBefore;
    final product = await _dao.productById(productId);
    final quantityChanged = quantityAfter != before;
    final thresholdChanged = thresholdAfter != thresholdBefore;
    if (!quantityChanged && !thresholdChanged) {
      return;
    }

    await _dao.transaction(() async {
      await _dao.updateInventory(
        productId,
        quantityAfter,
        now,
        lowStockThreshold: thresholdAfter,
      );
      if (quantityChanged) {
        await _dao.insertStockMovement(
          StockMovementsCompanion.insert(
            id: IdGenerator.create(),
            productId: productId,
            type: type,
            quantityChange: quantityAfter - before,
            quantityAfter: quantityAfter,
            referenceId: Value(productId),
            notes: Value(notes),
            createdAt: now,
          ),
        );
      }
    });

    await _auditRepository?.record(
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: quantityChanged
          ? 'inventory.adjust'
          : 'inventory.threshold.update',
      entityType: 'inventory',
      entityId: productId,
      description: quantityChanged && thresholdChanged
          ? 'Stok ${product?.name ?? productId} disesuaikan dari $before menjadi $quantityAfter dan batas minimum dari $thresholdBefore menjadi $thresholdAfter'
          : quantityChanged
          ? 'Stok ${product?.name ?? productId} disesuaikan dari $before menjadi $quantityAfter'
          : 'Batas minimum stok ${product?.name ?? productId} diubah dari $thresholdBefore menjadi $thresholdAfter',
      metadata: {
        'productId': productId,
        'type': type,
        'before': before,
        'after': quantityAfter,
        'change': quantityAfter - before,
        'thresholdBefore': thresholdBefore,
        'thresholdAfter': thresholdAfter,
      },
    );
  }
}
