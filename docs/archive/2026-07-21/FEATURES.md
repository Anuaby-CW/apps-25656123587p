# Features Catalog - Talaga Coffee POS (Flutter App)

Status terakhir diperbarui: 20 Juli 2026

## Legenda Status
- ✅ Aktif — fitur berjalan dan dipakai
- ⛔ Nonaktif — fitur pernah ada, sudah dinonaktifkan/dihapus dari flow utama (kode boleh masih ada atau sudah dihapus, tetap dicatat sebagai riwayat)

## Daftar Fitur

### 1. Autentikasi & Sesi (Auth)
- **Login & Sesi Multi-Role** — ✅ Aktif
  - Deskripsi: Mengotentikasi pengguna secara lokal menggunakan password yang di-hash. Menentukan rute pertama berdasarkan peran pengguna (Dashboard untuk Admin, POS untuk Kasir).
  - File terkait: [login_screen.dart](file:///lib/presentation/auth/login_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart), [auth_repository.dart](file:///lib/data/repositories/auth_repository.dart), [password_hasher.dart](file:///lib/core/auth/password_hasher.dart)
  - Dependency: `flutter_riverpod`, `crypto` (SHA-256 hashing)
  - Role: admin / kasir (keduanya)
  - Catatan: Akun bawaan di-seed otomatis pada saat inisialisasi awal database (`admin` / `123456` dan `kasir` / `123456`).

- **Pencegahan Sesi Bentrok (Shift Lock)** — ✅ Aktif
  - Deskripsi: Layar pelindung untuk mencegah kasir mengakses POS jika shift aktif yang sedang berjalan milik akun kasir lain. Memaksa pengguna masuk menggunakan pemilik shift saat ini atau keluar untuk mengganti kasir.
  - File terkait: [pos_screen.dart](file:///lib/presentation/pos/pos_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`
  - Role: kasir

---

### 2. Dashboard & Pemantauan (Dashboard)
- **Visualisasi Grafik Penjualan (Revenue Chart)** — ✅ Aktif
  - Deskripsi: Grafik visual untuk memantau omzet penjualan harian, kemarin, atau rentang waktu kustom, yang dibagi ke dalam beberapa ember (buckets) grafik.
  - File terkait: [dashboard_overview_screen.dart](file:///lib/presentation/dashboard/dashboard_overview_screen.dart), [dashboard_shell.dart](file:///lib/presentation/dashboard/dashboard_shell.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`, `fl_chart`
  - Role: admin

- **Analisis Komparasi Pendapatan (Revenue Comparison)** — ✅ Aktif
  - Deskripsi: Analisis ringkas untuk membandingkan pendapatan periode berjalan dengan periode sebelumnya (mingguan/bulanan), lengkap dengan perhitungan persentase naik/turun performa outlet.
  - File terkait: [dashboard_overview_screen.dart](file:///lib/presentation/dashboard/dashboard_overview_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart), [report_models.dart](file:///lib/domain/models/report_models.dart)
  - Dependency: `flutter_riverpod`
  - Role: admin

---

### 3. Layanan Kasir & POS (POS & Cart & Checkout)
- **Akses POS untuk Admin** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Tujuan POS disembunyikan dari navigasi dan ditolak oleh guard akses untuk role Admin. POS tetap aktif untuk Kasir.
  - Reaktivasi: `--dart-define=FEATURE_ADMIN_POS_ACCESS=true`
  - File terkait: [feature_flags.dart](file:///lib/core/config/feature_flags.dart), [app_destination.dart](file:///lib/core/routing/app_destination.dart)
  - Role saat nonaktif: kasir

- **Saringan Kategori & Subkategori Produk** — ✅ Aktif
  - Deskripsi: Menyaring menu minuman, makanan, atau biji kopi dengan memilih chip kategori utama dan subkategori agar pencarian menu menjadi lebih cepat dan efisien.
  - File terkait: [pos_screen.dart](file:///lib/presentation/pos/pos_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`
  - Role: kasir

- **Opsi Otonom Produk (Product Options Dialog)** — ✅ Aktif
  - Deskripsi: Dialog penyesuaian detail menu sebelum ditambahkan ke keranjang belanja, termasuk pilihan suhu (Hot/Ice), level gula (Normal/Less Sugar), catatan kustom, pilihan add-ons (ekstra shot, sirup), serta detail Manual Brew (pilihan metode seduh dan biji kopi).
  - File terkait: [pos_screen.dart](file:///lib/presentation/pos/pos_screen.dart) (bagian `_ProductOptionsDialog`), [cart_panel.dart](file:///lib/presentation/cart/cart_panel.dart)
  - Dependency: `flutter_riverpod`
  - Role: kasir

- **Keranjang Belanja Aktif (Cart Management)** — ✅ Aktif
  - Deskripsi: Pengelolaan item di dalam keranjang belanja seperti mengubah jumlah pesanan (quantity), memperbarui catatan, menghapus item, serta kalkulasi otomatis subtotal dan total harga secara real-time.
  - File terkait: [cart_panel.dart](file:///lib/presentation/cart/cart_panel.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart), [cart_models.dart](file:///lib/domain/models/cart_models.dart)
  - Dependency: `flutter_riverpod`
  - Role: kasir

- **Eksekusi Pembayaran Langsung (Checkout Flow)** — ✅ Aktif
  - Deskripsi: Menyelesaikan transaksi Dine In / Take Away melalui "Bayar Sekarang" dengan metode tunai. Nama pelanggan tetap wajib, sedangkan nomor meja tidak diminta selama feature flag-nya nonaktif.
  - File terkait: [checkout_dialog.dart](file:///lib/presentation/checkout/checkout_dialog.dart), [checkout_usecase.dart](file:///lib/domain/usecases/checkout_usecase.dart), [checkout_repository.dart](file:///lib/data/repositories/checkout_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

- **Shortcut Nama Pelanggan** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Chip `Pelanggan Umum` disembunyikan pada build standar. Field nama pelanggan tetap tersedia dan wajib diisi manual.
  - Reaktivasi: `--dart-define=FEATURE_CUSTOMER_NAME_SHORTCUT=true`
  - File terkait: [feature_flags.dart](file:///lib/core/config/feature_flags.dart), [checkout_dialog.dart](file:///lib/presentation/checkout/checkout_dialog.dart)

- **Nomor Meja & Bayar Nanti** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Input/chip nomor meja dan tombol Bayar Nanti disembunyikan. Checkout Dine In tidak mewajibkan meja; request Bayar Nanti ditolak pada lapisan use case.
  - Reaktivasi: `--dart-define=FEATURE_TABLE_NUMBER=true` dan `--dart-define=FEATURE_PAY_LATER=true`. Bayar Nanti wajib dirilis bersama Orders Queue agar order belum lunas dapat dikelola.
  - File terkait: [feature_flags.dart](file:///lib/core/config/feature_flags.dart), [checkout_dialog.dart](file:///lib/presentation/checkout/checkout_dialog.dart), [checkout_usecase.dart](file:///lib/domain/usecases/checkout_usecase.dart)

- **Input Cepat Nominal Tunai (Quick Cash Input)** — ✅ Aktif
  - Deskripsi: Menyediakan tombol cepat di dialog pembayaran untuk memilih nominal uang tunai populer (misal: Uang Pas, Rp 50.000, Rp 100.000) guna mempercepat proses transaksi.
  - File terkait: [quick_cash_input.dart](file:///lib/presentation/widgets/quick_cash_input.dart), [checkout_dialog.dart](file:///lib/presentation/checkout/checkout_dialog.dart)
  - Dependency: `flutter_riverpod`
  - Role: kasir

---

### 4. Antrean & Pembayaran Tunda (Orders)
- **Filter Status Antrean (Order Queue)** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Menu/tujuan Pesanan disembunyikan untuk semua role. Screen dan query filter tetap tersedia untuk reaktivasi melalui `--dart-define=FEATURE_ORDERS_QUEUE=true`.
  - File terkait: [orders_screen.dart](file:///lib/presentation/orders/orders_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`
  - Role saat nonaktif: tidak ada

- **Siklus Status Pesanan (Order Lifecycle Update)** — ⛔ Tidak tersedia dari UI
  - Deskripsi: Logika repository dipertahankan, tetapi aksi Disiapkan → Siap → Selesai tidak dapat diakses selama Orders Queue nonaktif.
  - File terkait: [orders_screen.dart](file:///lib/presentation/orders/orders_screen.dart), [orders_repository.dart](file:///lib/data/repositories/orders_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

- **Pelunasan Bayar Belakangan (Receive Payment)** — ⛔ Tidak tersedia dari UI
  - Deskripsi: Use case dan dialog dipertahankan, tetapi tidak dapat diakses selama Bayar Nanti dan Orders Queue nonaktif.
  - File terkait: [orders_screen.dart](file:///lib/presentation/orders/orders_screen.dart) (bagian `_ReceivePaymentDialog`), [receive_payment_usecase.dart](file:///lib/domain/usecases/receive_payment_usecase.dart), [checkout_repository.dart](file:///lib/data/repositories/checkout_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

- **Batal Pesanan & Pengembalian Stok** — ⛔ Tidak tersedia dari UI
  - Deskripsi: Logika pembatalan dan pemulihan stok dipertahankan, tetapi tidak dapat diakses selama Orders Queue nonaktif.
  - File terkait: [orders_screen.dart](file:///lib/presentation/orders/orders_screen.dart), [orders_repository.dart](file:///lib/data/repositories/orders_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

---

### 5. Shift & Arus Kas Kecil (Shift & Petty Cash)
- **Buka/Tutup Shift Kasir (Shift Management)** — ✅ Aktif
  - Deskripsi: Membuka sesi kerja kasir dengan mencatat modal awal (opening cash) di halaman Pengaturan (Settings) kasir. POS kasir terkunci jika shift belum dibuka. Jika akses POS Admin direaktivasi, Admin tetap dibebaskan dari kewajiban shift.
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart), [shift_reconciliation_dialog.dart](file:///lib/presentation/pos/shift_reconciliation_dialog.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir (admin dilewati)

- **Pencatatan Kas Keluar (Petty Cash)** — ✅ Aktif
  - Deskripsi: Menu bagi kasir untuk memasukkan nominal dan keterangan pengeluaran operasional outlet (kas kecil keluar) dari halaman Pengaturan (Settings) kasir selama shift aktif berjalan.
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart), [pos_screen.dart](file:///lib/presentation/pos/pos_screen.dart) (bagian `PettyCashDialog`), [app_database.dart](file:///lib/data/database/app_database.dart) (tabel PettyCash)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

---

### 6. Riwayat Transaksi (Transactions)
- **Buku Riwayat Struk Lunas** — ✅ Aktif
  - Deskripsi: Layar arsip bagi admin untuk melacak seluruh transaksi pembayaran lunas, rincian item pesanan, total belanja, metode bayar, serta nama kasir yang bertugas.
  - File terkait: [transactions_screen.dart](file:///lib/presentation/transactions/transactions_screen.dart)
  - Dependency: `flutter_riverpod`
  - Role: admin

---

### 7. Laporan & Ekspor Finansial (Reports)
- **Filter Laporan Penjualan** — ✅ Aktif
  - Deskripsi: Menyaring dan menampilkan omzet, transaksi lunas, tunai diterima, produk terlaris, dan penjualan per kategori berdasarkan rentang tanggal. Metrik pesanan belum lunas sudah dihapus dari UI.
  - File terkait: [reports_screen.dart](file:///lib/presentation/reports/reports_screen.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart)
  - Dependency: `flutter_riverpod`
  - Role: admin

- **Ekspor Ringkasan Laporan ke PDF** — ✅ Aktif
  - Deskripsi: Membuat berkas PDF resmi laporan penjualan yang berisi omzet, transaksi lunas, total tunai, produk terlaris, ranking produk, serta kontribusi penjualan per kategori. Berkas disimpan di direktori Downloads publik Android.
  - File terkait: [reports_screen.dart](file:///lib/presentation/reports/reports_screen.dart), [report_export_usecase.dart](file:///lib/domain/usecases/report_export_usecase.dart), [report_file_saver.dart](file:///lib/core/files/report_file_saver.dart)
  - Dependency: `flutter_riverpod`, `pdf`
  - Role: admin

- **Metrik Pesanan Dibatalkan** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Kartu laporan dan baris PDF pesanan dibatalkan disembunyikan pada build standar.
  - Reaktivasi: `--dart-define=FEATURE_CANCELLED_ORDERS_REPORT=true`
  - File terkait: [feature_flags.dart](file:///lib/core/config/feature_flags.dart), [reports_screen.dart](file:///lib/presentation/reports/reports_screen.dart), [report_export_usecase.dart](file:///lib/domain/usecases/report_export_usecase.dart)
  - Role saat nonaktif: tidak ada

---

### 8. Manajemen Menu & Racikan (Catalog Management)
- **Manajemen Kategori Produk (CRUD)** — ✅ Aktif
  - Deskripsi: Menambah, mengubah nama, menyetel urutan tampil, dan menonaktifkan kategori utama atau subkategori produk.
  - File terkait: [categories_screen.dart](file:///lib/presentation/categories/categories_screen.dart), [catalog_repository.dart](file:///lib/data/repositories/catalog_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

- **Manajemen Produk (CRUD)** — ✅ Aktif
  - Deskripsi: Menambahkan menu makanan/minuman baru ke katalog, menyetel harga dasar, harga khusus dingin/panas (Hot/Ice price), pelacakan persediaan (inventory track), serta menentukan apakah produk berkategori Manual Brew.
  - File terkait: [products_screen.dart](file:///lib/presentation/products/products_screen.dart), [catalog_repository.dart](file:///lib/data/repositories/catalog_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

- **Manajemen Add-ons / Ekstra (CRUD)** — ✅ Aktif
  - Deskripsi: Menambahkan item pelengkap menu (seperti topping, ekstra espresso shot, sirup) beserta harga jualnya agar dapat dikaitkan dengan pesanan kasir.
  - File terkait: [addons_screen.dart](file:///lib/presentation/addons/addons_screen.dart), [catalog_repository.dart](file:///lib/data/repositories/catalog_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

- **Manajemen Varian Biji Kopi (Beans CRUD)** — ✅ Aktif
  - Deskripsi: Khusus untuk menu bertanda Manual Brew, admin dapat menambahkan pilihan biji kopi (single origin) beserta harga porsi Hot dan Ice yang berbeda secara dinamis.
  - File terkait: [beans_screen.dart](file:///lib/presentation/beans/beans_screen.dart) (bagian `BeansScreen`), [catalog_repository.dart](file:///lib/data/repositories/catalog_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

- **Manajemen Metode Seduh Manual Brew (Methods CRUD)** — ⛔ Nonaktif
  - Deskripsi: Metode manual brew tidak lagi dikelola oleh admin maupun dipilih secara terpisah oleh kasir; Manual Brew kini hanya memerlukan pemilihan biji kopi (Beans).
  - File terkait: [beans_screen.dart](file:///lib/presentation/beans/beans_screen.dart) (bagian `ManualBrewMethodsScreen` - dinonaktifkan dari menu navigasi)
  - Role: N/A

---

### 9. Manajemen Persediaan Stok (Inventory)
- **Alarm Stok Minim (Low Stock Alert)** — ✅ Aktif
  - Deskripsi: Memantau ketersediaan barang secara real-time dan memberikan peringatan visual mencolok (warna oranye/terracotta) jika kuantitas barang saat ini berada di bawah batas minimum (`lowStockThreshold`) yang ditetapkan.
  - File terkait: [inventory_screen.dart](file:///lib/presentation/inventory/inventory_screen.dart)
  - Dependency: `flutter_riverpod`
  - Role: admin

- **Penyesuaian Stok Manual & Batas Minimum** — ✅ Aktif
  - Deskripsi: Dialog khusus untuk menambah stok (restock), mengoreksi stok jika ada selisih opname, serta memperbarui ambang batas stok minim dari masing-masing produk.
  - File terkait: [inventory_screen.dart](file:///lib/presentation/inventory/inventory_screen.dart) (bagian `_InventoryDialog`), [catalog_repository.dart](file:///lib/data/repositories/catalog_repository.dart) (metode `adjustStock`)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

---

### 10. Pengelolaan Tim Outlet (Users)
- **Kelola Akun Kasir & Admin (CRUD)** — ✅ Aktif
  - Deskripsi: Membuat akun pengguna baru, menyunting nama tampilan, memperbarui sandi masuk lokal, menetapkan hak akses (admin/kasir), serta mematikan akses masuk kasir (memblokir sementara) lewat tombol saklar aktif/nonaktif (`isActive`).
  - File terkait: [user_management_screen.dart](file:///lib/presentation/users/user_management_screen.dart), [user_repository.dart](file:///lib/data/repositories/user_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

---

### 11. Jurnal Aktivitas & Audit (Audit Trail)
- **Pencatatan Audit Trail Aktivitas Penting** — ✅ Aktif
  - Deskripsi: Layar pemantauan log aktivitas sistem untuk melacak kejadian perubahan kritis seperti pembuatan/penyuntingan menu, penyesuaian stok manual, modifikasi status pengguna, serta ekspor laporan.
  - File terkait: [audit_trail_screen.dart](file:///lib/presentation/audit/audit_trail_screen.dart), [audit_repository.dart](file:///lib/data/repositories/audit_repository.dart), [audit_dao.dart](file:///lib/data/database/daos/audit_dao.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

---

### 12. Pengaturan Outlet & Konektivitas Hardware (Settings)
- **Identitas Outlet & Informasi Struk** — ✅ Aktif
  - Deskripsi: Menyunting data utama outlet (Nama Toko, Alamat, WhatsApp, Instagram) serta baris teks penutup struk belanja yang akan dicetak di kertas kasir.
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart), [settings_repository.dart](file:///lib/data/repositories/settings_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin / kasir (keduanya)

- **Sambungan Printer Bluetooth Termal (ESC/POS)** — ✅ Aktif
  - Deskripsi: Fitur untuk memindai perangkat Bluetooth lokal, menyambungkan printer termal kasir, memilih ukuran kertas (58 mm atau 80 mm), serta melakukan cetak uji coba printer (test print).
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart), [android_bluetooth_printer_service.dart](file:///lib/core/printer/android_bluetooth_printer_service.dart), [bluetooth_permission_service.dart](file:///lib/core/permissions/bluetooth_permission_service.dart)
  - Dependency: `flutter_riverpod`, `print_bluetooth_thermal`, `esc_pos_utils_plus`
  - Role: kasir

- **Koneksi Laci Kasir Otomatis (Cash Drawer Kick)** — ✅ Aktif
  - Deskripsi: Memicu laci kasir uang fisik agar otomatis terbuka (mengirimkan ESB/POS pulse command) saat pembayaran tunai selesai divalidasi oleh kasir.
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart), [cash_drawer_service.dart](file:///lib/core/printer/cash_drawer_service.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart) (bagian `cashDrawerServiceProvider`)
  - Dependency: `flutter_riverpod`
  - Role: kasir

- **Log Aktivitas Cetak Printer** — ✅ Aktif
  - Deskripsi: Riwayat rekaman status cetak struk dari printer bluetooth (Sukses/Gagal) beserta deskripsi kegagalan guna mempermudah troubleshooting kegagalan hardware.
  - File terkait: [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart) (bagian `_printerLogSection`), [printer_log_repository.dart](file:///lib/data/repositories/printer_log_repository.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: kasir

- **Kontrol Pengelolaan Stok di Pengaturan** — ⛔ Nonaktif (kode dipertahankan)
  - Deskripsi: Panel switch `Pengelolaan Stok` disembunyikan dari Pengaturan Admin. Halaman Stok dan pencatatan persediaan tetap aktif.
  - Reaktivasi: `--dart-define=FEATURE_INVENTORY_MANAGEMENT_SETTING=true`
  - File terkait: [feature_flags.dart](file:///lib/core/config/feature_flags.dart), [settings_screen.dart](file:///lib/presentation/settings/settings_screen.dart)
  - Role saat nonaktif: tidak ada

- **Pembersihan Data Aman (Reset / Clear Data)** — ✅ Aktif
  - Deskripsi: Fitur khusus admin untuk mereset data SQLite yang digunakan UI secara terpilah: Riwayat Transaksi dan operasional kasir, Log Aktivitas & Printer, atau Katalog & Persediaan Bawaan. Opsi Keranjang Aktif dan Data Pelanggan tidak lagi ditampilkan.
  - File terkait: [reset_data_admin_panel.dart](file:///lib/presentation/settings/widgets/reset_data_admin_panel.dart), [data_management_section.dart](file:///lib/presentation/settings/widgets/data_management_section.dart), [reset_dao.dart](file:///lib/data/database/daos/reset_dao.dart)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin

---

### 13. Desain Sistem & Tema (Theme & Design System)
- **Role-based Dynamic Theme (Desain Visual Per-Peran)** — ✅ Aktif
  - Deskripsi: Mengubah skema warna primer antarmuka secara dinamis (warna cokelat kayu hangat/wood untuk kasir guna meningkatkan fokus & keramahan operasional; warna teal jernih/lake untuk admin demi menunjang kejelasan pemantauan data).
  - File terkait: [app_theme.dart](file:///lib/theme/app_theme.dart), [app_role_tokens.dart](file:///lib/theme/app_role_tokens.dart), [app_colors.dart](file:///lib/theme/app_colors.dart)
  - Dependency: `flutter_riverpod`
  - Role: admin / kasir (keduanya)

- **Persistent Dark Mode** — ✅ Aktif
  - Deskripsi: Fitur untuk berpindah mode tampilan gelap/terang (dark/light mode) secara global dan nilainya disimpan secara persisten ke database settings lokal.
  - File terkait: [app_theme.dart](file:///lib/theme/app_theme.dart), [app_providers.dart](file:///lib/presentation/providers/app_providers.dart) (bagian `DarkModeNotifier`)
  - Dependency: `flutter_riverpod`, `drift`
  - Role: admin / kasir (keduanya)

- **Komponen UI Modular Reusable** — ✅ Aktif
  - Deskripsi: Kumpulan template dan komponen visual kustom yang digunakan di seluruh layar (seperti `AppPageFrame`, `AppPageHeader`, `AppSectionCard`, `AppStatusBadge`, `AppStateView`) untuk menjamin keselarasan desain Material 3 yang premium.
  - File terkait: [app_page_frame.dart](file:///lib/widgets/common/app_page_frame.dart), [app_page_header.dart](file:///lib/widgets/common/app_page_header.dart), [app_section_card.dart](file:///lib/widgets/common/app_section_card.dart), [app_state_view.dart](file:///lib/widgets/common/app_state_view.dart), [app_status_badge.dart](file:///lib/widgets/common/app_status_badge.dart)
  - Dependency: SDK Flutter Material
  - Role: admin / kasir (keduanya)

- **Animasi Umpan Balik Mikro (Micro-Animations)** — ✅ Aktif
  - Deskripsi: Animasi pantulan kecil (bounce animation) interaktif pada tombol/item belanja saat kasir memasukkan produk ke keranjang belanja untuk memberikan respons antarmuka yang terasa dinamis dan premium.
  - File terkait: [pos_screen.dart](file:///lib/presentation/pos/pos_screen.dart) (bagian `PosMicroBounce` & `_PosMicroBounceState`)
  - Dependency: SDK Flutter Widgets
  - Role: kasir

- **Komponen Alert Modern (AppAlert)** — ✅ Aktif
  - Deskripsi: Komponen kustom SnackBar dengan desain modern, rounded corners, bayangan premium, status ikon, dan skema warna kontras tinggi disesuaikan dengan mode terang/gelap untuk menggantikan dialog pesan bawaan yang default.
  - File terkait: [app_alert.dart](file:///lib/widgets/common/app_alert.dart)
  - Role: admin / kasir (keduanya)

---

## Laporan Penonaktifan — 17 Juli 2026

| Area | Hasil |
|---|---|
| Build standar | Keempat flag bernilai `false`; shortcut pelanggan, nomor meja, Bayar Nanti, dan menu Pesanan tidak tersedia. |
| Proteksi bisnis | Request `payNow: false` ditolak dengan pesan `Bayar Nanti sedang dinonaktifkan`. |
| Preservasi | Screen Orders, dialog/use case pembayaran tertunda, field meja, schema, dan data lama tidak dihapus. |
| Reaktivasi | Dilakukan saat build memakai `--dart-define`; panduan dan prompt tersedia di `DEACTIVATED_FEATURES.md`. |
| Verifikasi default | Seluruh suite: 58 test lulus, 4 test legacy dilewati karena membutuhkan `FEATURE_PAY_LATER=true`. |
| Verifikasi reaktivasi | 38 test terarah lulus tanpa skip ketika keempat flag diaktifkan. |
| Static analysis | Bersih (`No issues found`) setelah 9 penggunaan `BuildContext` lintas async gap pada screen Orders/Settings diperbaiki. |

---

## Riwayat Perubahan Status

| Tanggal | Fitur | Status Baru | Alasan |
|---|---|---|---|
| 20 Juli 2026 | Akses POS Admin | ⛔ Nonaktif (dipertahankan) | Menu dan guard akses POS dibatasi ke Kasir; reaktivasi tersedia melalui feature flag. |
| 20 Juli 2026 | Metrik Pesanan Belum Lunas | ⛔ Dihapus dari laporan | Kartu UI dan baris ekspor PDF dihapus karena Bayar Nanti/Orders Queue tidak aktif pada build standar. |
| 20 Juli 2026 | Metrik Pesanan Dibatalkan | ⛔ Nonaktif (dipertahankan) | Kartu UI dan baris ekspor PDF disembunyikan melalui feature flag. |
| 20 Juli 2026 | Panel Reset Data | Diperbarui | Pilihan diselaraskan dengan kelompok data SQLite aktif; Keranjang Aktif dan Data Pelanggan dihapus dari panel. |
| 20 Juli 2026 | Kontrol Pengelolaan Stok di Pengaturan | ⛔ Nonaktif (dipertahankan) | Switch pengelolaan stok disembunyikan; halaman Stok tetap aktif. |
| 17 Juli 2026 | Navigasi Kasir Compact | Diperbaiki | Bottom navigation tidak dirender bila tujuan efektif kurang dari dua, sehingga penonaktifan Orders Queue tidak melanggar assertion Flutter. |
| 17 Juli 2026 | Shortcut Nama Pelanggan | ⛔ Nonaktif (dipertahankan) | Disembunyikan melalui feature flag; dapat diaktifkan kembali saat build. |
| 17 Juli 2026 | Nomor Meja & Bayar Nanti | ⛔ Nonaktif (dipertahankan) | UI nomor meja/Bayar Nanti disembunyikan dan request pembayaran tunda diblokir; kode serta data lama dipertahankan. |
| 17 Juli 2026 | Antrean Pesanan (Orders Queue) | ⛔ Nonaktif (dipertahankan) | Tujuan Pesanan ditutup untuk semua role melalui feature flag; screen dan data tidak dihapus. |
| 17 Juli 2026 | Riwayat Printer | Diperbarui | Log printer otomatis dibatasi maksimal 4 entri dan log berganti hari dihapus otomatis. |
| 17 Juli 2026 | Metode Manual Brew | ⛔ Nonaktif | Pengelolaan metode seduh manual brew dinonaktifkan (CRUD admin & dropdown kasir dihapus), kini hanya menggunakan pilihan biji kopi (Beans). |
| 17 Juli 2026 | Buka/Tutup Shift & Kas Keluar | Diperbarui | Layar POS kasir bersih dari kontrol shift, dipindahkan ke menu Pengaturan (Settings). |
| 17 Juli 2026 | Navigasi Admin (Quick Access) | Diperbarui | Bilah navigasi/ribbon admin dibuat dinamis (tidak fixed) menggunakan NestedScrollView. |
| 17 Juli 2026 | Riwayat Aktivitas Admin | Diperbarui | Log aktivitas audit otomatis dibatasi maksimal 9 entri dan log berganti hari dihapus otomatis. |
| 17 Juli 2026 | Komponen Alert / Toast | Diperbarui | Mengganti dialog/alert bawaan yang default dengan komponen modern kustom `AppAlert`. |
