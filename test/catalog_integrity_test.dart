import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/data/database/app_database.dart';
import 'package:talaga_coffee_pos/data/database/daos/catalog_dao.dart';
import 'package:talaga_coffee_pos/data/repositories/catalog_repository.dart';

void main() {
  late AppDatabase database;
  late CatalogDao dao;
  late CatalogRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = CatalogDao(database);
    repository = CatalogRepository(dao);
    await repository.saveCategory(
      id: 'cat_test',
      name: 'Kategori Test',
      type: 'drink',
    );
  });

  tearDown(() => database.close());

  Future<void> saveProduct(
    String id, {
    bool trackInventory = true,
    int initialStock = 0,
    int lowStockThreshold = 5,
  }) {
    return repository.saveProduct(
      id: id,
      name: 'Produk $id',
      categoryId: 'cat_test',
      basePrice: 10000,
      trackInventory: trackInventory,
      initialStock: initialStock,
      lowStockThreshold: lowStockThreshold,
    );
  }

  test(
    'product with order-item history must be deactivated, not deleted',
    () async {
      const productId = 'prod_order_history';
      await saveProduct(productId, trackInventory: false);
      await database
          .into(database.orderItems)
          .insert(
            OrderItemsCompanion.insert(
              id: 'item_history',
              orderId: 'order_history',
              productId: const Value(productId),
              productNameSnapshot: 'Produk Riwayat',
              categoryNameSnapshot: 'Kategori Test',
              unitPrice: 10000,
              quantity: 1,
              subtotal: 10000,
            ),
          );

      await expectLater(
        repository.deleteProduct(productId),
        _throwsStateErrorContaining('Nonaktifkan produk'),
      );
      expect(
        (await repository.snapshot(activeOnly: false)).products,
        contains(predicate<ProductRecord>((row) => row.id == productId)),
      );
    },
  );

  test('product with stock-movement history must not be deleted', () async {
    const productId = 'prod_stock_history';
    await saveProduct(productId, initialStock: 5);

    await expectLater(
      repository.deleteProduct(productId),
      _throwsStateErrorContaining('Nonaktifkan produk'),
    );
    expect(await dao.stockMovementsForProduct(productId), isNotEmpty);
    expect(await dao.productById(productId), isNotNull);
  });

  test('deleting a never-used product cleans all mutable joins', () async {
    const productId = 'prod_clean_delete';
    await saveProduct(productId, initialStock: 0);
    await repository.saveAddon(
      id: 'addon_clean_delete',
      name: 'Add-on Test',
      price: 2000,
    );
    await repository.updateProductAddons(productId, const [
      'addon_clean_delete',
    ]);
    await repository.setProductFavorite(
      userId: 'user_test',
      productId: productId,
      isFavorite: true,
    );

    await repository.deleteProduct(productId);

    final snapshot = await repository.snapshot(activeOnly: false);
    expect(snapshot.products.where((row) => row.id == productId), isEmpty);
    expect(
      snapshot.productAddons.where((row) => row.productId == productId),
      isEmpty,
    );
    expect(snapshot.inventoryByProductId[productId], isNull);
    expect(
      await repository.watchFavoriteProductIds('user_test').first,
      isNot(contains(productId)),
    );
  });

  test(
    'tracking toggle without history removes and safely recreates stock',
    () async {
      const productId = 'prod_toggle_clean';
      await saveProduct(productId, initialStock: 0, lowStockThreshold: 4);
      expect((await dao.inventoryForProduct(productId))?.quantity, 0);

      await saveProduct(productId, trackInventory: false);
      var snapshot = await repository.snapshot(activeOnly: false);
      expect(snapshot.inventoryByProductId[productId], isNull);
      expect(snapshot.trackedInventory, isEmpty);

      await saveProduct(productId, initialStock: 99, lowStockThreshold: 7);
      snapshot = await repository.snapshot(activeOnly: false);
      expect(snapshot.inventoryByProductId[productId]?.quantity, 0);
      expect(snapshot.inventoryByProductId[productId]?.lowStockThreshold, 7);
      expect(snapshot.trackedInventory.single.productId, productId);
    },
  );

  test(
    'tracking toggle preserves historical stock but hides it while off',
    () async {
      const productId = 'prod_toggle_history';
      await saveProduct(productId, initialStock: 5);

      await saveProduct(productId, trackInventory: false);
      var snapshot = await repository.snapshot(activeOnly: false);
      expect(snapshot.inventoryByProductId[productId]?.quantity, 5);
      expect(
        snapshot.trackedInventory.where((row) => row.productId == productId),
        isEmpty,
      );
      expect(
        snapshot.lowStockInventory.where((row) => row.productId == productId),
        isEmpty,
      );

      await saveProduct(productId);
      snapshot = await repository.snapshot(activeOnly: false);
      expect(snapshot.inventoryByProductId[productId]?.quantity, 5);
      expect(
        snapshot.trackedInventory
            .singleWhere((row) => row.productId == productId)
            .quantity,
        5,
      );
    },
  );

  test('active category rejects an inactive parent', () async {
    await repository.saveCategory(
      id: 'cat_inactive_parent',
      name: 'Induk Nonaktif',
      type: 'drink',
      isActive: false,
    );

    await expectLater(
      repository.saveCategory(
        id: 'cat_active_child',
        name: 'Anak Aktif',
        type: 'drink',
        parentId: 'cat_inactive_parent',
      ),
      _throwsStateErrorContaining('induk nonaktif'),
    );

    await repository.saveCategory(
      id: 'cat_inactive_child',
      name: 'Anak Nonaktif',
      type: 'drink',
      parentId: 'cat_inactive_parent',
      isActive: false,
    );
    expect(
      (await repository.allCategories())
          .singleWhere((row) => row.id == 'cat_inactive_child')
          .isActive,
      isFalse,
    );
  });
}

Matcher _throwsStateErrorContaining(String text) {
  return throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'message',
      contains(text),
    ),
  );
}
