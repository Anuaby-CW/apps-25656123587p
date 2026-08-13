import 'package:drift/drift.dart';

import '../../core/auth/password_hasher.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import 'app_database.dart';

class SeedData {
  SeedData(this._db, {PasswordHasher hasher = const PasswordHasher()})
    : _hasher = hasher;

  final AppDatabase _db;
  final PasswordHasher _hasher;

  Future<void> ensureSeeded() async {
    final existing = await (_db.select(
      _db.settings,
    )..where((tbl) => tbl.key.equals('seed_version'))).getSingleOrNull();
    if (existing?.value == '2') {
      await _insertSettingIfMissing(
        'outlet_instagram',
        AppConstants.defaultOutletInstagram,
      );
      return;
    }

    await _db.transaction(() async {
      if (existing == null) {
        await _seedUsers();
        await _seedCatalog();
        await _seedSettings();
      } else {
        await _localizeSeedCategoryNames();
      }
      await _insertSettingIfMissing(
        'outlet_instagram',
        AppConstants.defaultOutletInstagram,
      );
      await _upsertSetting('seed_version', '2');
    });
  }

  /// Replaces catalog and inventory reference data with the defaults bundled
  /// in this offline application.
  ///
  /// Clearing and re-seeding happen in one transaction so a failed seed never
  /// leaves the outlet with a partially empty catalog.
  Future<void> resetCatalogToBundledDefaults() {
    return _db.transaction(() async {
      await _db.delete(_db.stockMovements).go();
      await _db.delete(_db.inventory).go();
      await _db.delete(_db.productAddons).go();
      await _db.delete(_db.productFavorites).go();
      await _db.delete(_db.addons).go();
      await _db.delete(_db.beans).go();
      await _db.delete(_db.manualBrewMethods).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.categories).go();
      await _seedCatalog();
    });
  }

  Future<void> _seedUsers() async {
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insert(
        _db.users,
        UsersCompanion.insert(
          id: 'user_admin',
          username: AppConstants.defaultAdminUsername,
          passwordHash: _hasher.hash(AppConstants.defaultPassword),
          role: UserRole.admin.name,
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      batch.insert(
        _db.users,
        UsersCompanion.insert(
          id: 'user_kasir',
          username: AppConstants.defaultCashierUsername,
          passwordHash: _hasher.hash(AppConstants.defaultPassword),
          role: UserRole.cashier.name,
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> _localizeSeedCategoryNames() async {
    const translations = {
      'Signature': 'Menu Andalan',
      'Coffee / Espresso Based': 'Kopi / Berbasis Espresso',
      'Non Coffee': 'Non-Kopi',
      'Signature Snacks': 'Camilan Andalan',
      'Noodle & Soup': 'Mi & Sup',
      'Savory Bites': 'Camilan Gurih',
      'Rice Meals': 'Menu Nasi',
    };
    for (final entry in translations.entries) {
      await (_db.update(
        _db.categories,
      )..where((tbl) => tbl.name.equals(entry.key))).write(
        CategoriesCompanion(
          name: Value(entry.value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _seedCatalog() async {
    final now = DateTime.now();
    final categories = [
      _category('cat_drink', 'Minuman', null, 'drink', 1, now),
      _category('cat_food', 'Makanan', null, 'food', 2, now),
      _category('cat_signature', 'Menu Andalan', 'cat_drink', 'drink', 1, now),
      _category(
        'cat_coffee',
        'Kopi / Berbasis Espresso',
        'cat_drink',
        'drink',
        2,
        now,
      ),
      _category('cat_non_coffee', 'Non-Kopi', 'cat_drink', 'drink', 3, now),
      _category('cat_manual_brew', 'Manual Brew', 'cat_drink', 'drink', 4, now),
      _category(
        'cat_signature_snacks',
        'Camilan Andalan',
        'cat_food',
        'food',
        1,
        now,
      ),
      _category('cat_noodle_soup', 'Mi & Sup', 'cat_food', 'food', 2, now),
      _category(
        'cat_savory_bites',
        'Camilan Gurih',
        'cat_food',
        'food',
        3,
        now,
      ),
      _category('cat_rice_meals', 'Menu Nasi', 'cat_food', 'food', 4, now),
    ];

    final products = <ProductsCompanion>[
      _drink(
        'prod_talaga_aren',
        'Talaga Aren',
        'cat_signature',
        22000,
        24000,
        1,
        now,
      ),
      _drink(
        'prod_butterscotch_latte',
        'Butterscotch Latte',
        'cat_signature',
        24000,
        26000,
        2,
        now,
      ),
      _drink(
        'prod_matcha_latte_signature',
        'Matcha Latte',
        'cat_signature',
        23000,
        25000,
        3,
        now,
      ),
      _drink('prod_americano', 'Americano', 'cat_coffee', 17000, 19000, 1, now),
      _drink(
        'prod_cafe_latte',
        'Cafe Latte',
        'cat_coffee',
        21000,
        23000,
        2,
        now,
      ),
      _drink(
        'prod_cappuccino',
        'Cappuccino',
        'cat_coffee',
        21000,
        23000,
        3,
        now,
      ),
      _drink(
        'prod_vanilla_latte',
        'Vanilla Latte',
        'cat_coffee',
        23000,
        25000,
        4,
        now,
      ),
      _drink('prod_espresso', 'Espresso', 'cat_coffee', 14000, 14000, 5, now),
      _drink(
        'prod_chocolate',
        'Chocolate',
        'cat_non_coffee',
        20000,
        22000,
        1,
        now,
      ),
      _drink(
        'prod_matcha_latte',
        'Matcha Latte',
        'cat_non_coffee',
        22000,
        24000,
        2,
        now,
      ),
      _drink(
        'prod_red_velvet',
        'Red Velvet',
        'cat_non_coffee',
        21000,
        23000,
        3,
        now,
      ),
      _drink(
        'prod_taro_latte',
        'Taro Latte',
        'cat_non_coffee',
        21000,
        23000,
        4,
        now,
      ),
      _drink(
        'prod_choco_hazelnut',
        'Choco Hazelnut',
        'cat_non_coffee',
        23000,
        25000,
        5,
        now,
      ),
      _drink(
        'prod_cookies_cream',
        'Cookies & Cream',
        'cat_non_coffee',
        23000,
        25000,
        6,
        now,
      ),
      _drink(
        'prod_bandrek_susu',
        'Bandrek Susu',
        'cat_non_coffee',
        16000,
        18000,
        7,
        now,
      ),
      _drink(
        'prod_bandrek_ori',
        'Bandrek Ori',
        'cat_non_coffee',
        13000,
        15000,
        8,
        now,
      ),
      _drink(
        'prod_lemon_tea',
        'Lemon Tea',
        'cat_non_coffee',
        14000,
        16000,
        9,
        now,
      ),
      _drink(
        'prod_extra_espresso',
        'Extra Espresso',
        'cat_non_coffee',
        7000,
        7000,
        10,
        now,
      ),
      _drink(
        'prod_mineral_water',
        'Mineral Water',
        'cat_non_coffee',
        6000,
        6000,
        11,
        now,
      ),
      ProductsCompanion.insert(
        id: 'prod_manual_brew',
        name: 'Manual Brew',
        categoryId: 'cat_manual_brew',
        basePrice: 0,
        hotPrice: const Value(null),
        icePrice: const Value(null),
        trackInventory: const Value(false),
        isManualBrew: const Value(true),
        sortOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
      _food(
        'prod_pisang_keju',
        'Pisang Keju',
        'cat_signature_snacks',
        18000,
        1,
        now,
      ),
      _food(
        'prod_ubi_coklat',
        'Ubi Coklat',
        'cat_signature_snacks',
        16000,
        2,
        now,
      ),
      _food('prod_ubi_keju', 'Ubi Keju', 'cat_signature_snacks', 16000, 3, now),
      _food(
        'prod_pisang_coklat',
        'Pisang Coklat',
        'cat_signature_snacks',
        17000,
        4,
        now,
      ),
      _food(
        'prod_pisang_goreng_ori',
        'Pisang Goreng Ori',
        'cat_signature_snacks',
        14000,
        5,
        now,
      ),
      _food(
        'prod_indomie_tektek',
        'Indomie Tektek',
        'cat_noodle_soup',
        18000,
        1,
        now,
      ),
      _food(
        'prod_indomie_polos',
        'Indomie Polos',
        'cat_noodle_soup',
        12000,
        2,
        now,
      ),
      _food(
        'prod_indomie_telor',
        'Indomie Telor',
        'cat_noodle_soup',
        15000,
        3,
        now,
      ),
      _food(
        'prod_indomie_baso',
        'Indomie Baso',
        'cat_noodle_soup',
        17000,
        4,
        now,
      ),
      _food(
        'prod_baso_cuanki',
        'Baso Cuanki',
        'cat_noodle_soup',
        18000,
        5,
        now,
      ),
      _food('prod_pop_mie', 'Pop Mie', 'cat_noodle_soup', 10000, 6, now),
      _food(
        'prod_tempe_mendoan',
        'Tempe Mendoan',
        'cat_savory_bites',
        13000,
        1,
        now,
      ),
      _food('prod_tahu_isi', 'Tahu Isi', 'cat_savory_bites', 12000, 2, now),
      _food(
        'prod_kentang_goreng',
        'Kentang Goreng',
        'cat_savory_bites',
        17000,
        3,
        now,
      ),
      _food(
        'prod_sosis_bakar_goreng',
        'Sosis Bakar / Goreng',
        'cat_savory_bites',
        18000,
        4,
        now,
      ),
      _food(
        'prod_cireng_ayam',
        'Cireng Ayam',
        'cat_savory_bites',
        16000,
        5,
        now,
      ),
      _food(
        'prod_nasi_ayam_komplit',
        'Nasi Ayam Komplit',
        'cat_rice_meals',
        27000,
        1,
        now,
      ),
      _food(
        'prod_nasi_ikan_komplit',
        'Nasi Ikan Komplit',
        'cat_rice_meals',
        27000,
        2,
        now,
      ),
      _food(
        'prod_nasi_goreng_biasa',
        'Nasi Goreng Biasa',
        'cat_rice_meals',
        22000,
        3,
        now,
      ),
      _food(
        'prod_nasi_goreng_special',
        'Nasi Goreng Special',
        'cat_rice_meals',
        28000,
        4,
        now,
      ),
      _food(
        'prod_nasi_telor_dadar',
        'Nasi Telor Dadar Komplit',
        'cat_rice_meals',
        19000,
        5,
        now,
      ),
    ];

    final addons = [
      _addon('addon_oat_milk', 'Oat Milk', 6000, now),
      _addon('addon_vanilla', 'Vanilla Syrup', 4000, now),
      _addon('addon_caramel', 'Caramel Syrup', 4000, now),
      _addon('addon_hazelnut', 'Hazelnut Syrup', 4000, now),
      _addon('addon_extra_shot', 'Extra Shot Espresso', 7000, now),
    ];

    final beans = [
      _bean('bean_fullwash', 'Fullwash', 23000, 25000, now),
      _bean('bean_honey', 'Honey', 25000, 27000, now),
      _bean('bean_natural', 'Natural', 26000, 28000, now),
      _bean('bean_wine', 'Wine', 28000, 30000, now),
    ];

    final methods = [
      _method('method_v60', 'V60', 1, now),
      _method('method_japanese', 'Japanese Style', 2, now),
      _method('method_vietnam_drip', 'Vietnam Drip', 3, now),
      _method('method_aeropress', 'AeroPress', 4, now),
      _method('method_french_press', 'French Press', 5, now),
    ];

    await _db.batch((batch) {
      batch.insertAll(
        _db.categories,
        categories,
        mode: InsertMode.insertOrIgnore,
      );
      batch.insertAll(_db.products, products, mode: InsertMode.insertOrIgnore);
      batch.insertAll(_db.addons, addons, mode: InsertMode.insertOrIgnore);
      batch.insertAll(_db.beans, beans, mode: InsertMode.insertOrIgnore);
      batch.insertAll(
        _db.manualBrewMethods,
        methods,
        mode: InsertMode.insertOrIgnore,
      );
    });

    await _seedProductAddons(products, addons);
    await _seedInventory(products);
  }

  Future<void> _seedProductAddons(
    List<ProductsCompanion> products,
    List<AddonsCompanion> addons,
  ) async {
    final drinkProducts = products
        .where(
          (product) =>
              product.categoryId.value.startsWith('cat_') &&
              !_boolValue(product.isManualBrew, defaultValue: false),
        )
        .where((product) => product.categoryId.value != 'cat_signature_snacks')
        .where((product) => product.categoryId.value != 'cat_noodle_soup')
        .where((product) => product.categoryId.value != 'cat_savory_bites')
        .where((product) => product.categoryId.value != 'cat_rice_meals')
        .toList();

    final rows = <ProductAddonsCompanion>[];
    for (final product in drinkProducts) {
      for (final addon in addons) {
        rows.add(
          ProductAddonsCompanion.insert(
            id: '${product.id.value}_${addon.id.value}',
            productId: product.id.value,
            addonId: addon.id.value,
          ),
        );
      }
    }
    await _db.batch((batch) {
      batch.insertAll(_db.productAddons, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> _seedInventory(List<ProductsCompanion> products) async {
    final now = DateTime.now();
    final rows = products
        .where(
          (product) => _boolValue(product.trackInventory, defaultValue: true),
        )
        .map(
          (product) => InventoryCompanion.insert(
            id: 'inv_${product.id.value}',
            productId: product.id.value,
            quantity: const Value(50),
            lowStockThreshold: const Value(5),
            updatedAt: now,
          ),
        )
        .toList();
    await _db.batch((batch) {
      batch.insertAll(_db.inventory, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> _seedSettings() async {
    await _upsertSetting('outlet_name', AppConstants.defaultOutletName);
    await _upsertSetting('outlet_address', AppConstants.defaultOutletAddress);
    await _upsertSetting('outlet_whatsapp', AppConstants.defaultOutletWhatsapp);
    await _upsertSetting(
      'outlet_instagram',
      AppConstants.defaultOutletInstagram,
    );
    await _upsertSetting('receipt_footer', AppConstants.defaultReceiptFooter);
    await _upsertSetting('inventory_enabled', 'true');
    await _db
        .into(_db.printerSettings)
        .insert(
          PrinterSettingsCompanion.insert(updatedAt: DateTime.now()),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _upsertSetting(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(id: 'setting_$key', key: key, value: value),
        );
  }

  Future<void> _insertSettingIfMissing(String key, String value) {
    return _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(id: 'setting_$key', key: key, value: value),
          mode: InsertMode.insertOrIgnore,
        );
  }

  CategoriesCompanion _category(
    String id,
    String name,
    String? parentId,
    String type,
    int sortOrder,
    DateTime now,
  ) {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      parentId: Value(parentId),
      type: type,
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
  }

  ProductsCompanion _drink(
    String id,
    String name,
    String categoryId,
    int hotPrice,
    int icePrice,
    int sortOrder,
    DateTime now,
  ) {
    return ProductsCompanion.insert(
      id: id,
      name: name,
      categoryId: categoryId,
      basePrice: hotPrice,
      hotPrice: Value(hotPrice),
      icePrice: Value(icePrice),
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
  }

  ProductsCompanion _food(
    String id,
    String name,
    String categoryId,
    int price,
    int sortOrder,
    DateTime now,
  ) {
    return ProductsCompanion.insert(
      id: id,
      name: name,
      categoryId: categoryId,
      basePrice: price,
      hotPrice: Value(price),
      icePrice: Value(price),
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
  }

  AddonsCompanion _addon(String id, String name, int price, DateTime now) {
    return AddonsCompanion.insert(
      id: id,
      name: name,
      price: price,
      createdAt: now,
      updatedAt: now,
    );
  }

  BeansCompanion _bean(
    String id,
    String name,
    int hotPrice,
    int icePrice,
    DateTime now,
  ) {
    return BeansCompanion.insert(
      id: id,
      name: name,
      hotPrice: hotPrice,
      icePrice: icePrice,
      createdAt: now,
      updatedAt: now,
    );
  }

  ManualBrewMethodsCompanion _method(
    String id,
    String name,
    int sortOrder,
    DateTime now,
  ) {
    return ManualBrewMethodsCompanion.insert(
      id: id,
      name: name,
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
  }

  bool _boolValue(Value<bool> value, {required bool defaultValue}) {
    return value.present ? value.value : defaultValue;
  }
}
