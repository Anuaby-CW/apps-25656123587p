# Data Model and Persistence Rules

## Baseline

- Storage: Drift/SQLite lokal.
- `schemaVersion`: 5.
- Table count: 21.
- `PRAGMA foreign_keys = ON` dijalankan, tetapi table declaration saat ini belum memakai `.references(...)`; sebagian besar relasi dijaga oleh repository/transaction.
- Nominal uang disimpan sebagai integer dan ditampilkan sebagai Rupiah.

## Entitas aktif

| Kelompok | Table | Peran |
|---|---|---|
| Identity | `Users` | Akun lokal, role, status, password hash, login metadata |
| Catalog | `Categories` | Kategori bertingkat dan urutan |
| Catalog | `Products` | Produk, harga, status, inventory/manual-brew flags |
| Catalog | `Addons`, `ProductAddons` | Master add-on dan relasi many-to-many |
| Catalog | `Beans` | Beans serta harga Hot/Ice |
| Inventory | `Inventory` | Current quantity dan low-stock threshold per product |
| Inventory | `StockMovements` | Ledger perubahan stock dan ending balance |
| Customer | `Customers` | Snapshot identitas pelanggan; belum menjadi CRM |
| Sales | `Orders` | Header order, customer snapshot, status, subtotal/discount/tax/total |
| Sales | `OrderItems` | Snapshot item, options, beans, add-on JSON, note |
| Sales | `Payments` | Metode, amount received, change, cashier, paid time |
| Sales | `Transactions` | Nomor transaksi untuk order lunas |
| Operations | `PettyCash` | Kas keluar, nominal, note, cashier, timestamp |
| System | `Settings` | Key-value identitas outlet, dark mode, dan state shift |
| System | `PrinterSettings` | Konfigurasi printer/kertas/drawer |
| System | `AuditLogs` | Audit event dan metadata |
| System | `PrinterLogs` | Event perangkat dan error detail |

## Entitas kompatibilitas tanpa UI aktif

| Table | Status |
|---|---|
| `ProductFavorites` | Dipertahankan; tidak ada kontrol favorit aktif |
| `ManualBrewMethods` | Dipertahankan; Manual Brew aktif memakai beans + Hot/Ice |
| `CafeTables` | Dipertahankan; checkout standar tidak membaca master table |

Orders/items juga menyimpan field lama yang mendukung nomor meja, order belum lunas, atau flow yang diparkir. Lihat `DEACTIVATED_FEATURES.md`.

## Relasi logis penting

- `Products.categoryId -> Categories.id`
- `ProductAddons.productId -> Products.id`
- `ProductAddons.addonId -> Addons.id`
- `Inventory.productId -> Products.id` dengan satu baris logis per product.
- `Orders.cashierId/customerId -> Users/Customers`
- `OrderItems.orderId/productId -> Orders/Products`
- `Payments.orderId/cashierId -> Orders/Users`
- `Transactions.orderId/paymentId/cashierId -> Orders/Payments/Users`
- `StockMovements.productId -> Products`

Karena constraint referensial belum dideklarasikan penuh, operasi delete/reset harus menjaga invariant secara eksplisit dan memiliki regression test.

## Transaction boundaries

Wajib atomik:

- Checkout: customer/order/items/payment/transaction/stock movement.
- Reset data dan pemulihan dampak stock.
- Mutation katalog/inventory yang mengubah beberapa row terkait.
- Unit bisnis lain yang tidak boleh menghasilkan state parsial, walaupun hanya menyentuh satu table beberapa kali.

Tidak masuk transaction database:

- Printer dan cash drawer.
- Generate/save/share PDF.
- Permission prompt dan `MethodChannel` side effect.
- UI notification.

## Schema migration checklist

1. Tentukan kebutuhan kompatibilitas instalasi lama dan rollback/data-loss risk.
2. Ubah table declaration atau daftar `@DriftDatabase`/DAO.
3. Naikkan `schemaVersion` tepat satu versi untuk perubahan terencana.
4. Tambahkan jalur `onUpgrade` dari seluruh versi lama yang masih didukung.
5. Jalankan `dart run build_runner build`.
6. Tambahkan test fresh install dan upgrade dari schema sebelumnya.
7. Verifikasi reset/seed/export yang membaca schema terkait.
8. Jangan edit `.g.dart` secara manual.

## Seed bukan schema

`seed_version` mengatur bootstrap/lokalisasi data bawaan. Perubahan katalog/default setting harus mengevaluasi `SeedData.ensureSeeded()` dan reset katalog. Jangan menaikkan `schemaVersion` hanya karena isi seed berubah.

## Known limitations

- Shift aktif disimpan dalam `Settings`; belum ada table histori `Shifts`.
- Petty cash belum memiliki `shiftId` foreign key.
- Rekonsiliasi uang fisik/selisih tidak dipersist sebagai histori lengkap.
- Discount/tax tersedia di schema, tetapi checkout aktif menulis nol.
- Sequence nomor order/transaksi berbasis record ber-prefix tanggal dan perlu diperhatikan pada concurrency/multi-device di masa depan.

