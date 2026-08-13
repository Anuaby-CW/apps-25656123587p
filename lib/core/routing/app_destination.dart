import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../../domain/models/enums.dart';

enum AppDestination {
  dashboard(Icons.dashboard_outlined, 'Dashboard', true),
  pos(Icons.point_of_sale, 'POS', false),
  orders(Icons.receipt_long_outlined, 'Pesanan', false),
  transactions(Icons.payments, 'Transaksi', true),
  reports(Icons.bar_chart, 'Laporan', true),
  products(Icons.local_cafe, 'Produk', true),
  categories(Icons.category, 'Kategori', true),
  inventory(Icons.inventory_2, 'Stok', true),
  beans(Icons.coffee, 'Biji Kopi', true),
  addons(Icons.add_circle_outline, 'Add-ons', true),
  users(Icons.people, 'Pengguna', true),
  auditTrail(Icons.manage_search, 'Riwayat Aktivitas', true),
  settings(Icons.settings, 'Pengaturan', false);

  const AppDestination(this.icon, this.label, this.adminOnly);

  final IconData icon;
  final String label;
  final bool adminOnly;

  bool isAllowed(UserRole role) {
    if (this == orders) {
      return FeatureFlags.ordersQueue;
    }
    if (this == pos) {
      return role == UserRole.cashier || FeatureFlags.adminPosAccess;
    }
    return !adminOnly || role == UserRole.admin;
  }

  static AppDestination initialForRole(UserRole role) =>
      role == UserRole.admin ? dashboard : pos;

  static List<AppDestination> forRole(UserRole role) =>
      values.where((destination) => destination.isAllowed(role)).toList();
}
