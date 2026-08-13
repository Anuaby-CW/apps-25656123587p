# Product Requirements Document — Talaga Coffee POS

> Jenis dokumen: PRD *as-is* berdasarkan isi repository pada 21 Juli 2026.  
> Status verifikasi: `flutter test` lulus 75 pengujian dengan 4 pengujian kompatibilitas dilewati sesuai feature flag; `flutter analyze` selesai tanpa isu pada 21 Juli 2026.  
> Arti status: `done` = alur pengguna dan lapisan pendukungnya tersedia; `in-progress` = implementasi baru sebagian atau tidak terhubung ke alur pengguna; `planned` = ada sinyal eksplisit/kuat di kode, tetapi alur belum tersedia.

## 1. Overview

Talaga Coffee POS adalah aplikasi point-of-sale Flutter untuk ponsel dan tablet Android. Aplikasi dirancang tetap dapat menjalankan operasi utama tanpa internet, dengan transaksi dan data operasional disimpan secara lokal di SQLite melalui Drift.

Produk memisahkan dua ruang kerja berdasarkan peran:

- **Kasir** menjalankan shift, memilih produk, mengelola keranjang, menerima pembayaran tunai langsung, mencetak struk, mencatat kas keluar, dan menutup shift.
- **Admin** memantau dashboard dan laporan, melihat transaksi lunas, serta mengelola katalog, stok, pengguna, aktivitas, identitas outlet, dan reset data.

Arsitektur yang benar-benar ditemukan mengikuti pembagian `core/`, `data/`, `domain/`, `presentation/`, `theme/`, dan `widgets/`. State aplikasi dirangkai dengan Riverpod; sebagian besar akses SQLite memakai DAO dan repository; aturan checkout, struk, harga Manual Brew, dan ekspor laporan ditempatkan sebagai use case. Alur shift dan petty cash mengakses DAO/database langsung dari provider. Integrasi Android native dipakai untuk izin Bluetooth dan penyimpanan PDF ke Downloads.

Tech stack yang ditemukan langsung di project:

- Flutter/Dart dengan Material 3 dan `flutter_localizations`.
- Riverpod untuk state management.
- Drift + SQLite untuk penyimpanan lokal, skema versi 5.
- `print_bluetooth_thermal` dan `esc_pos_utils_plus` untuk printer Bluetooth/ESC-POS.
- `pdf`, `share_plus`, `fl_chart`, `image`, `intl`, `crypto`, dan UUID v7.
- Kotlin/Java 17 untuk integrasi Android melalui `MethodChannel`.

Bukti utama: `README.md`, `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/presentation/providers/app_providers.dart`, dan `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt`.

## 2. Problem Statement

Berdasarkan README dan alur bisnis di kode, produk ini menangani kebutuhan operasional outlet kopi berikut:

1. Penjualan harus tetap dapat dicatat ketika koneksi internet tidak tersedia.
2. Kasir membutuhkan alur cepat dari pemilihan menu sampai pembayaran tunai dan pencetakan struk.
3. Data pesanan, pembayaran, transaksi, stok, dan laporan harus tetap konsisten, termasuk ketika data transaksi direset.
4. Admin membutuhkan kontrol lokal atas katalog, stok, pengguna, laporan, dan konfigurasi outlet tanpa masuk ke alur kasir.
5. Perangkat outlet seperti printer termal dan laci kas perlu diintegrasikan tanpa membuat transaksi finansial gagal hanya karena perangkat periferal bermasalah.
6. Pergantian kasir perlu dicatat melalui buka/tutup shift, modal awal, kas keluar, uang fisik, dan selisih kas.

## 3. Target User / Role

| Role | Tujuan dan akses yang ditemukan | Batas akses yang ditemukan |
|---|---|---|
| **Admin** | Dashboard, Transaksi, Laporan, Produk, Kategori, Stok, Biji Kopi, Add-ons, Pengguna, Riwayat Aktivitas, identitas outlet, dan reset data. | Tidak memperoleh POS maupun panel printer/laci kas pada build standar. |
| **Kasir** | POS, buka/tutup shift, petty cash, pembayaran tunai langsung, pencetakan struk, serta Pengaturan printer/laci kas. | Tidak dapat membuka modul admin atau panel reset data destruktif. |

Tidak ditemukan role pelanggan. Pelanggan hanya menjadi data yang melekat pada pesanan.

Bukti: `lib/core/routing/app_destination.dart:5-38`, `lib/presentation/dashboard/dashboard_shell.dart:600-626`, dan `lib/presentation/settings/settings_screen.dart:122-197`.

## 4. Scope

### 4.1 Termasuk dalam implementasi repository saat ini

- Aplikasi Flutter Android yang beroperasi dengan database lokal.
- Login lokal dan navigasi berbasis role Admin/Kasir.
- Seed akun, katalog, inventori, pengaturan outlet, dan printer bawaan.
- Buka shift, modal awal, petty cash, rekonsiliasi, tutup shift, laporan thermal, dan berbagi PDF shift.
- Katalog POS Minuman/Makanan, kategori bertingkat, opsi Panas/Dingin, gula, Manual Brew berbasis biji kopi, add-on, jumlah, dan catatan.
- Keranjang dan checkout tunai melalui alur Bayar Sekarang.
- Nama pelanggan wajib diisi manual.
- Sugesti nominal pembayaran cepat dan formatter input Rupiah dengan batas 12 digit.
- Pengurangan/pemulihan stok, penyesuaian manual, batas stok minimum, dan riwayat pergerakan stok.
- Struk ESC/POS 58 mm dan 80 mm, logo thermal, cetak ulang, serta laci kas melalui printer.
- Dashboard, transaksi lunas, laporan periode, grafik, ranking, dan ekspor PDF.
- CRUD produk, kategori, add-on, biji kopi, dan pengguna.
- Audit trail dengan cakupan event tertentu, log perangkat printer, pengaturan outlet, dark mode, dan reset data granular.
- Tema responsif yang berbeda untuk tamu, kasir, dan admin; bahasa utama Indonesia dan format Rupiah.
- PDF closing shift yang memuat total serta rincian waktu, keperluan, dan nominal kas keluar.
- Feedback kasir dan log perangkat ketika laci kas checkout gagal terbuka.

### 4.2 Belum termasuk sebagai kapabilitas selesai

- Pembayaran QRIS atau integrasi DANA/merchant online; UI masih dinonaktifkan.
- CRM pelanggan, deduplikasi/lookup pelanggan, dan loyalty.
- Input nomor HP pelanggan dari checkout; field data masih ada, tetapi UI sengaja tidak mengirimkannya.
- Diskon, promo, dan pajak yang dapat dikonfigurasi; kolom `discount` dan `tax` ada tetapi checkout menulis nilai nol.
- Pencarian/barcode produk, kanal delivery, dan persediaan bahan baku; tidak ditemukan alur atau konfigurasi terkait.
- Sinkronisasi cloud, API backend, multi-device, dan konflik data; tidak ditemukan dependency atau implementasi jaringan pada alur release.
- Target iOS, web, atau desktop; metadata project hanya mencantumkan root dan Android.
- Signing Android produksi; konfigurasi release masih memakai signing debug.

Fitur yang diparkir dan artefak kompatibilitas lama tidak diulang sebagai
requirement produk aktif. Status, dampak, dan cara reaktivasinya menjadi source
of truth di `DEACTIVATED_FEATURES.md`.

Dokumen `.agents/AGENT.md` menyebut backend Laravel/Filament dan outlet single-branch, tetapi tidak ada source/config integrasinya di repository ini. Karena itu, klaim tersebut tidak dimasukkan ke scope pasti dan dipindahkan ke Open Questions.

## 5. Functional Requirements

### 5.1 Fondasi aplikasi, autentikasi, dan navigasi

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-FND-01 | Aplikasi melakukan bootstrap locale, memasang `ProviderScope`, membuka database lokal, menjalankan migrasi, dan menambahkan seed yang belum tersedia. | `done` | `lib/main.dart:7-10`; `lib/data/database/app_database.dart:342-372`; `lib/data/database/seed_data.dart` |
| FR-FND-02 | Pengguna dapat login dengan username/password lokal. Password diverifikasi dari hash SHA-256 dengan pepper; akun nonaktif ditolak dan waktu login terakhir diperbarui. | `done` | `lib/data/repositories/auth_repository.dart:20-31`; `lib/core/auth/password_hasher.dart:7-17` |
| FR-FND-03 | Sistem menyediakan akun bawaan Admin `admin` dan Kasir `kasir`, masing-masing dengan password awal `123456`. | `done` | `README.md:7-10`; `lib/core/constants/app_constants.dart:6-9`; `lib/data/database/seed_data.dart:63-90` |
| FR-FND-04 | Menu, tujuan awal, dan workspace difilter berdasarkan role. Admin masuk ke Dashboard; Kasir masuk ke POS. | `done` | `lib/core/routing/app_destination.dart:27-38`; `lib/presentation/dashboard/dashboard_shell.dart` |
| FR-FND-05 | Logout menghapus sesi in-memory, membersihkan keranjang, dan mengembalikan pilihan navigasi ke POS. | `done` | `lib/presentation/providers/app_providers.dart:191-226` |
| FR-FND-06 | Workspace Admin dan Kasir menggunakan navigasi serta tema berbeda; dark mode tersimpan pada setting lokal. | `done` | `lib/presentation/dashboard/dashboard_shell.dart`; `lib/presentation/providers/app_providers.dart:765-784`; `lib/theme/app_theme.dart` |

### 5.2 POS, keranjang, dan shift Kasir

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-POS-01 | Kasir wajib membuka shift dengan modal awal sebelum POS dapat dipakai. Satu shift aktif terikat pada satu akun kasir dan POS menolak akun lain. | `done` | `lib/presentation/pos/pos_screen.dart:39-96`; `lib/presentation/pos/shift_reconciliation_dialog.dart:30-185` |
| FR-POS-02 | Kasir dapat memilih jenis menu Minuman/Makanan, subkategori, dan produk aktif; kartu menampilkan harga dan stok. | `done` | `lib/presentation/pos/pos_screen.dart:309-597` |
| FR-POS-03 | Produk minuman dapat dikonfigurasi dengan Panas/Dingin dan gula; produk Manual Brew mewajibkan biji kopi serta suhu; add-on, jumlah, dan catatan dapat ditambahkan. | `done` | `lib/presentation/pos/pos_screen.dart`; `lib/domain/usecases/manual_brew_pricing.dart` |
| FR-POS-04 | Harga Manual Brew dihitung dari biji kopi terpilih dan pilihan Hot/Ice. | `done` | `lib/domain/usecases/manual_brew_pricing.dart:1-11`; `test/pos_business_rules_test.dart` |
| FR-POS-05 | Keranjang menggabungkan baris yang identik, menghitung subtotal termasuk add-on, serta mendukung ubah jumlah/suhu/gula/catatan, hapus baris, dan kosongkan keranjang. | `done` | `lib/presentation/providers/app_providers.dart:247-353`; `lib/presentation/cart/cart_panel.dart` |
| FR-POS-06 | Layout POS memakai katalog+keranjang dual-pane pada layar lebar dan floating cart/bottom sheet pada layar mobile. | `done` | `lib/presentation/pos/pos_screen.dart:116-306`; `lib/theme/app_layout.dart` |
| FR-POS-07 | Kasir dapat mencatat petty cash/kas keluar dengan nominal dan keterangan hanya ketika memiliki shift aktif. | `done` | `lib/presentation/pos/pos_screen.dart:906-1029`; `lib/presentation/providers/app_providers.dart:718-757` |
| FR-POS-08 | Tutup shift menghitung modal awal + penjualan tunai − petty cash, menerima uang fisik, menampilkan selisih, mencoba mencetak laporan thermal/membuka laci, dan menyediakan PDF multi-halaman dengan rincian kas keluar. | `done` | `lib/presentation/pos/shift_reconciliation_dialog.dart` |

### 5.3 Checkout, pembayaran, dan pesanan

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-CHK-01 | Checkout aktif mendukung Dine In dan Take Away serta mewajibkan nama pelanggan. | `done` | `lib/presentation/checkout/checkout_dialog.dart`; `lib/domain/usecases/checkout_usecase.dart` |
| FR-CHK-02 | Bayar Sekarang memvalidasi uang tunai dan, bila pengelolaan stok global aktif, memvalidasi stok; dalam transaksi database sistem membuat customer snapshot, order, item, payment, transaction, serta pengurangan/stock movement untuk item yang dilacak. | `done` | `lib/domain/usecases/checkout_usecase.dart:31-115`; `lib/data/repositories/checkout_repository.dart:60-197` |
| FR-CHK-03 | Setelah Bayar Sekarang tersimpan, sistem mencoba mencetak struk. Kegagalan printer dilaporkan tetapi tidak membatalkan transaksi finansial. | `done` | `lib/domain/usecases/checkout_usecase.dart:181-228` |
| FR-CHK-04 | Jika laci kas diaktifkan, printer berhasil, dan ada kembalian, sistem mencoba membuka laci. Kegagalan tidak membatalkan transaksi, tetapi ditampilkan kepada kasir dan ditulis ke log perangkat. | `done` | `lib/domain/usecases/checkout_usecase.dart`; `lib/presentation/checkout/checkout_dialog.dart` |
| FR-CHK-10 | Struk berbayar dapat dicetak dalam format ESC/POS 58 mm atau 80 mm dan memuat identitas outlet, pelanggan, tipe order, item/opsi, pembayaran, serta logo. | `done` | `lib/core/printer/receipt_formatter_58mm.dart`; `lib/core/printer/receipt_formatter_80mm.dart`; `test/receipt_logo_test.dart` |
| FR-CHK-11 | Checkout menyediakan cetak tambahan 1–10 salinan dan shortcut 2/3 salinan setelah pembayaran berhasil. | `done` | `lib/presentation/checkout/checkout_dialog.dart:131-167,513-588` |
| FR-CHK-12 | QRIS tampil sebagai metode pembayaran, tetapi pilihan dinonaktifkan dan submit diblokir karena API/akun merchant belum dikonfigurasi. | `planned` | `lib/domain/models/enums.dart:64-80`; `lib/presentation/checkout/checkout_dialog.dart:75-85,371-441` |
| FR-CHK-15 | Sistem menampilkan pilihan nominal pembayaran cepat yang dihitung dari total belanja, termasuk Uang Pas dan pembulatan pecahan Rupiah. | `done` | `lib/presentation/widgets/quick_cash_input.dart`; `lib/core/utils/idr_amount_input_formatter.dart` |
| FR-CHK-16 | Input nominal tunai menyaring karakter nonangka, memberi pemisah ribuan, menjaga posisi kursor, dan membatasi input hingga 12 digit sebagai batas nominal aplikasi. | `done` | `lib/core/utils/idr_amount_input_formatter.dart` |
| FR-CHK-17 | Sistem mencatat diagnostik fase checkout/printer; keberhasilan atau kegagalan laci kas checkout juga ditulis ke log perangkat. | `done` | `lib/core/utils/checkout_logger.dart`; `lib/data/repositories/printer_log_repository.dart` |

Detail kode yang diparkir tidak menjadi requirement aktif di bagian ini dan
didokumentasikan terpusat dalam `DEACTIVATED_FEATURES.md`.

### 5.4 Dashboard, transaksi, dan laporan Admin

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-RPT-01 | Dashboard menampilkan ringkasan omzet/transaksi hari ini, perbandingan kemarin, perbandingan mingguan/bulanan, dan peringatan stok minimum. | `done` | `lib/presentation/dashboard/dashboard_overview_screen.dart:165-743` |
| FR-RPT-02 | Admin dapat memilih periode harian, tujuh hari, atau rentang khusus; melihat distribusi/tren omzet atau transaksi; ranking produk; dan omzet per kategori. | `done` | `lib/presentation/dashboard/dashboard_overview_screen.dart:706-1426` |
| FR-RPT-03 | Modul Transaksi hanya menampilkan order lunas dengan nomor transaksi/pesanan, pelanggan, waktu, total, item, bayar, dan kembalian. | `done` | `lib/presentation/transactions/transactions_screen.dart` |
| FR-RPT-04 | Laporan mendukung Hari Ini, Kemarin, 7 Hari, dan rentang khusus; metrik aktifnya omzet, transaksi lunas, tunai diterima, produk terlaris, ranking produk, dan omzet per kategori. | `done` | `lib/presentation/reports/reports_screen.dart`; `lib/data/repositories/reports_repository.dart` |
| FR-RPT-05 | Hanya pembayaran/order lunas yang masuk omzet dan transaksi; tunai diterima tidak menghitung kembalian sebagai pemasukan. | `done` | `lib/data/database/daos/reports_dao.dart`; `test/pos_business_rules_test.dart` |
| FR-RPT-06 | Admin dapat mengekspor laporan PDF A4 berisi ringkasan, ranking produk, dan omzet kategori ke `Downloads/Talaga Coffee`; ekspor dicatat ke audit trail. | `done` | `lib/domain/usecases/report_export_usecase.dart`; `lib/core/files/report_file_saver.dart`; `MainActivity.kt:156-225` |

### 5.5 Katalog, racikan, dan stok Admin

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-CAT-01 | Admin dapat menambah, mengubah, mengaktifkan/nonaktifkan, dan menghapus produk; mengatur kategori, harga dasar/Hot/Ice, Manual Brew, pelacakan stok, stok awal, batas minimum, dan add-on terkait. | `done` | `lib/presentation/products/products_screen.dart`; `lib/data/repositories/catalog_repository.dart:87-253` |
| FR-CAT-02 | Produk yang sudah mempunyai riwayat order/stock tidak boleh dihapus; produk yang belum pernah dipakai membersihkan relasi mutable ketika dihapus. | `done` | `lib/data/database/daos/catalog_dao.dart:148-176`; `test/catalog_integrity_test.dart` |
| FR-CAT-03 | Admin dapat mengelola kategori utama/subkategori, tipe Minuman/Makanan/Add-on, status aktif, dan urutan. Kontrol pengurutan tersedia pada layout non-wide; parent/type dan referensi produk divalidasi. | `done` | `lib/presentation/categories/categories_screen.dart`; `lib/data/repositories/catalog_repository.dart:255-322` |
| FR-CAT-04 | Admin dapat mengelola add-on beserta harga dan status aktif. | `done` | `lib/presentation/addons/addons_screen.dart`; `lib/data/repositories/catalog_repository.dart:325-350` |
| FR-CAT-05 | Admin dapat mengelola biji kopi dengan harga Hot/Ice dan status aktif. | `done` | `lib/presentation/beans/beans_screen.dart`; `lib/data/repositories/catalog_repository.dart:352-379` |
| FR-STK-01 | Admin dapat melihat produk yang dilacak, status aman/menipis, kuantitas, batas minimum, dan delapan pergerakan terakhir. | `done` | `lib/presentation/inventory/inventory_screen.dart` |
| FR-STK-02 | Admin dapat mengubah stok akhir, tipe/keterangan pergerakan, dan batas minimum per produk; perubahan menulis stock movement dan audit log. | `done` | `lib/data/repositories/catalog_repository.dart:403-485`; `test/pos_business_rules_test.dart` |

### 5.6 Pengguna, aktivitas, pengaturan, dan data

| ID | Requirement berbasis implementasi | Status | Bukti utama |
|---|---|---|---|
| FR-USR-01 | Admin dapat melihat, menambah, mengubah, mengaktifkan/nonaktifkan, mereset password, dan menghapus pengguna Admin/Kasir. | `done` | `lib/presentation/users/user_management_screen.dart`; `lib/data/repositories/user_repository.dart` |
| FR-USR-02 | Sistem mempertahankan minimal satu Admin aktif dan mencegah perubahan/penghapusan yang berbahaya terhadap akun sendiri, pemilik shift aktif, dan pengguna dengan riwayat terkait. | `done` | `lib/data/repositories/user_repository.dart:22-45,69-99,131-182`; `test/pos_business_rules_test.dart` |
| FR-AUD-01 | Admin dapat melihat dan menyegarkan hingga 100 audit log terbaru. | `done` | `lib/presentation/audit/audit_trail_screen.dart`; `lib/data/repositories/audit_repository.dart:43-45` |
| FR-AUD-02 | Event yang benar-benar menulis audit saat ini mencakup perubahan/aktivasi produk, penyesuaian/threshold stok, ekspor laporan, operasi printer/laci tertentu, dan reset admin. | `done` *(cakupan terbatas)* | `lib/data/repositories/catalog_repository.dart`; `lib/domain/usecases/report_export_usecase.dart`; `lib/presentation/settings/settings_screen.dart`; `reset_data_admin_panel.dart` |
| FR-SET-01 | Admin dapat mengubah nama/alamat outlet, WhatsApp, Instagram, footer struk, dan nama tampilan user bawaan `user_kasir`. | `done` | `lib/presentation/settings/settings_screen.dart` |
| FR-SET-02 | Kasir dapat meminta izin Bluetooth/lokasi, mencari printer terpasang, memilih printer, connect/disconnect, memilih kertas 58/80 mm, dan mencetak uji. | `done` | `lib/presentation/settings/settings_screen.dart:278-373,509-741`; `lib/core/permissions/bluetooth_permission_service.dart` |
| FR-SET-03 | Kasir dapat mengaktifkan dan menguji laci kas melalui printer, serta melihat delapan log operasi perangkat terbaru. | `done` | `lib/presentation/settings/settings_screen.dart:374-480,742-778` |
| FR-SET-04 | Admin dapat mereset secara selektif transaksi, audit/printer log, serta katalog+persediaan bawaan setelah konfirmasi password Admin. Keranjang aktif dikosongkan langsung dari POS. | `done` | `lib/presentation/settings/widgets/reset_data_admin_panel.dart`; `lib/data/repositories/reset_repository.dart` |
| FR-SET-05 | Reset transaksi memulihkan dampak stok penjualan, menghapus payment/order/transaction/petty cash dan state shift aktif; reset katalog menolak meninggalkan order aktif tanpa referensi. | `done` | `lib/data/database/daos/reset_dao.dart:42-139`; `test/pos_business_rules_test.dart` |

## 6. Non-Functional Requirements

Hanya requirement yang mempunyai indikasi langsung di repository yang dicantumkan.

| Area | Requirement/keadaan yang ditemukan | Status/bukti |
|---|---|---|
| **Ketersediaan offline** | Login, katalog, checkout, pembayaran, stok, laporan, dan setting utama harus berjalan dari penyimpanan lokal tanpa backend. Manifest sumber `main` tidak mendeklarasikan Internet; izin Internet eksplisit hanya ditemukan pada overlay debug/profile. | `done` — `README.md:3`; Drift/SQLite; manifest Android |
| **Integritas data** | Checkout, reset, dan beberapa perubahan katalog/stok memakai transaksi database agar perubahan terkait berhasil atau gagal bersama. | `done` — repository/DAO terkait dan test aturan bisnis |
| **Migrasi lokal** | Database menggunakan schema version 5 dengan jalur migrasi aditif untuk instalasi lama. | `done` — `lib/data/database/app_database.dart:347-368` |
| **Keamanan lokal** | Password tidak disimpan sebagai plaintext; akses menu dipisah per role; akun nonaktif ditolak; reset destruktif meminta password Admin; pemilik shift dan Admin terakhir dilindungi. | Kontrol dasar tersedia; kecukupan keamanan produksi belum divalidasi — `password_hasher.dart`, routing, user/reset repository |
| **Ketahanan periferal** | Penyimpanan transaksi terjadi sebelum cetak. Kegagalan periferal tidak mengembalikan transaksi atau penutupan shift; kegagalan printer dilaporkan, sedangkan kegagalan laci checkout ditampilkan kepada kasir dan dicatat pada log perangkat. | `done` — checkout use case, dialog checkout, dan shift dialog |
| **Kompatibilitas perangkat** | Printer memakai Bluetooth/ESC-POS 58/80 mm. Izin disesuaikan versi Android. PDF memakai MediaStore pada Android Q+ dan folder Downloads legacy pada versi lama. | `done` pada kode; perangkat nyata belum diuji dalam suite — manifest dan `MainActivity.kt` |
| **Responsivitas** | UI mempunyai kelas lebar compact 600 px, expanded/dual-pane 840 px, large 1200 px, extra-large 1600 px, serta helper wide lama 1024 px. Layout juga menjaga kondisi tinggi layar di bawah 480 px. | `done` dan diuji — `lib/theme/app_layout.dart`; `test/app_layout_test.dart`; `test/adaptive_shell_test.dart` |
| **Lokalisasi** | Locale utama `id_ID`, format tanggal Indonesia, dan mata uang Rupiah. UI utama memakai Bahasa Indonesia. | `done` — `lib/app.dart`, formatter, dan tests |
| **Aksesibilitas visual** | Terdapat semantic header/loading/status/product label; tema terang/gelap dan pasangan warna diuji terhadap rasio kontras WCAG. | `done` pada komponen yang diuji — theme/accessibility tests |
| **Maintainability** | Project memakai lint Flutter, code generation Drift, repository/use case, serta dokumentasi langkah build/test/analyze. | `done` — `analysis_options.yaml`, `README.md`, struktur `lib/` |
| **Kualitas otomatis** | Suite mencakup aturan bisnis, database, fitur, logo/struk, tema, akses, dan layout adaptif. Tidak ditemukan `integration_test`, CI, target coverage, benchmark, atau pengujian perangkat printer/laci. | Unit/widget dan static analysis tersedia; hasil verifikasi terbaru dicatat pada header dokumen |
| **Packaging produksi** | Build release masih memakai debug signing dan workspace hanya berisi APK debug. | `in-progress` — `android/app/build.gradle.kts:24-27`; `README.md:136` |
| **Kesehatan dependency/build** | `sqlite3_flutter_libs` memakai versi berlabel `+eol`; generated Gradle report memuat sembilan warning sintaks menuju Gradle 10, tetapi asal warning belum teridentifikasi. | Perlu tindak lanjut; belum ada rencana di repository |

Tidak ditemukan target terukur untuk waktu startup, latensi checkout, volume maksimum katalog/transaksi, memori, storage, retensi data, backup, availability SLA, atau recovery time. Nilai-nilai tersebut tidak diasumsikan dalam PRD ini.

## 7. Data Model / Entities

Database Drift mempunyai 21 tabel pada schema version 5. Relasi di bawah adalah relasi logis berdasarkan kolom ID/string. Tidak ditemukan deklarasi `.references(...)`, walaupun `PRAGMA foreign_keys = ON` dijalankan.

| Kelompok | Entitas | Ringkasan dan relasi utama |
|---|---|---|
| **Identitas** | `Users` | Akun dengan username unik, display name, password hash, role, status aktif, waktu dibuat/diubah, dan login terakhir. Direferensikan secara logis oleh order, payment, transaction, petty cash, dan audit. |
| **Katalog** | `Categories` | Kategori bertingkat melalui `parentId`, tipe yang dipakai UI/repository (`drink`, `food`, atau `addon`), urutan, dan status aktif. Schema tidak memberi check constraint untuk tipe. |
|  | `Products` | Produk terkait `categoryId`; menyimpan harga dasar/Hot/Ice, flag aktif, pelacakan inventori, Manual Brew, dan urutan. |
|  | `Addons`, `ProductAddons` | Master add-on dan join many-to-many produk–add-on. |
|  | `Beans` | Master biji kopi dengan harga Hot dan Ice. |
| **Persediaan** | `Inventory` | Satu baris logis per produk melalui `productId` unik; menyimpan kuantitas dan batas stok minimum. |
|  | `StockMovements` | Ledger perubahan stok dengan tipe, perubahan kuantitas, saldo akhir, referensi, catatan, dan waktu. |
| **Pelanggan** | `Customers` | Nama dan telepon. Checkout saat ini membuat record baru/snapshot; tidak ada lookup, deduplikasi, atau layar pengelolaan. |
| **Penjualan** | `Orders` | Nomor order unik, kasir, customer ID/snapshot, tipe order, status pembayaran, subtotal, discount, tax, total, dan catatan. `discount` dan `tax` saat ini selalu nol. |
|  | `OrderItems` | Detail order dengan snapshot nama produk/kategori, harga, jumlah, opsi suhu/gula, biji Manual Brew, add-on JSON, dan catatan. Snapshot menjaga histori ketika master katalog berubah. |
|  | `Payments` | Pembayaran yang mengacu logis ke order/kasir, metode, uang diterima, kembalian, dan waktu bayar. Implementasi aktif saat ini selalu tunai. |
|  | `Transactions` | Nomor transaksi unik yang menghubungkan order, payment, kasir, total, dan waktu. Hanya dibuat untuk order lunas. |
| **Operasional kas** | `PettyCash` | Kas keluar dengan nominal, catatan, ID/nama kasir, dan waktu. Tidak mempunyai foreign key atau `shiftId`. |
| **Sistem** | `Settings` | Key-value generik untuk identitas outlet, footer, dark mode, dan state shift (`shift_active`, kasir, waktu mulai, modal awal). Tidak ada tabel `Shifts`. |
|  | `PrinterSettings` | Konfigurasi singleton-style untuk printer Bluetooth, alamat, tipe, ukuran kertas, toggle laci, status koneksi terakhir, dan waktu update. |
|  | `AuditLogs` | Actor, action, entity, deskripsi, metadata JSON, dan waktu untuk event yang direkam. |
|  | `PrinterLogs` | Jenis event perangkat, printer, alamat, status, pesan, dan waktu. |

Schema tetap mendaftarkan 21 tabel. Tabel dan jalur data kompatibilitas yang
tidak memiliki UI aktif dirangkum di `DEACTIVATED_FEATURES.md`, bukan dijadikan
requirement aktif dalam PRD ini.

Catatan model penting:

- Nominal uang disimpan sebagai integer dan diformat sebagai Rupiah.
- Nomor order berformat `TLG-YYYYMMDD-NNNN` dan nomor transaksi `TRX-YYYYMMDD-NNNN`, dengan sequence empat digit berdasarkan jumlah record ber-prefix sama.
- Shift aktif disimpan pada `Settings`; uang fisik, expected cash, dan selisih tutup shift hanya dihitung/dicetak/dibagikan, tidak dipersist sebagai riwayat rekonsiliasi.

## 8. Open Questions / Assumptions

### 8.1 Open Questions

1. Apakah QRIS memang akan memakai DANA? `api-dana.md` hanya berisi indeks dokumentasi eksternal dan tidak terhubung ke source, credential, client HTTP, webhook, atau konfigurasi merchant.
2. Jika QRIS diaktifkan, bagaimana kebutuhan konektivitas, callback/webhook, retry, dan rekonsiliasi pembayaran akan dipadukan dengan prinsip offline-first? Manifest sumber `main` saat ini tidak mendeklarasikan izin Internet.
3. Apakah nomor HP pelanggan sengaja dihapus dari checkout? Jika ya, apakah field/detail nomor HP dan tabel `Customers` masih diperlukan?
4. Apakah pelanggan perlu lookup, deduplikasi, histori, atau CRM? Saat ini tidak ada layar pengelolaan pelanggan maupun entitas loyalty.
5. Apakah hasil rekonsiliasi tutup shift harus dipersist agar Admin dapat melihat histori modal, kas tunai, petty cash, selisih, dan siapa yang menutup shift?
6. Apakah pengaturan printer/laci memang hanya untuk Kasir? Admin dapat membuka Pengaturan, tetapi hanya melihat identitas outlet dan reset data.
7. Pengaturan Admin mengubah “Nama kasir” melalui user ID hardcoded `user_kasir`, sementara modul Pengguna dapat membuat lebih dari satu Kasir. Perilaku apa yang diinginkan untuk multi-kasir?
8. Seberapa luas audit trail yang dibutuhkan? Login, user CRUD, checkout, dan buka/tutup shift belum otomatis ditulis ke audit log.
9. Apakah diskon, promo, dan pajak memang direncanakan, atau kolom tersebut hanya cadangan schema?
10. Apakah relasi database perlu dideklarasikan sebagai foreign key/cascade/check constraint? Saat ini relasi dijaga terutama oleh repository, bukan constraint schema.
11. Apakah keamanan produksi menerima password awal `123456`, SHA-256 dengan pepper tetap, password minimum enam karakter, tanpa salt per user/KDF adaptif, tanpa rate limit, dan tanpa kewajiban ganti password pertama?
12. Apakah session login memang harus hilang setiap aplikasi dimulai ulang, atau perlu persistensi sesi?
13. Berapa versi minimum/target Android dan matriks perangkat/printer/laci yang harus menjadi acceptance resmi?
14. Apakah dibutuhkan target performa, kapasitas, retensi/backup data, proteksi PDF di Downloads, CI, coverage minimum, integration test perangkat, dan uji upgrade database nyata?
15. Kapan debug signing, dependency `sqlite3_flutter_libs` berlabel EOL, dan warning kompatibilitas Gradle harus diselesaikan sebelum distribusi?
16. `.agents/AGENT.md` menyebut single-branch di Tangerang dan backend Laravel 13 + Filament v5, tetapi repository ini tidak memiliki backend/integrasi. Apakah dokumen tersebut masih berlaku?
17. `.agents/AGENT.md` menunjuk `.agent/design.md` sebagai source of truth desain, tetapi file/direktori itu tidak ada. Di mana dokumen desain yang berlaku?
18. Apa tujuan `flutter_01.png` di root? File tersebut tidak direferensikan oleh source atau konfigurasi sehingga tidak dapat dipastikan sebagai requirement aktif.
19. Kontrak repository laporan menyebut batas akhir periode inklusif, sedangkan DAO memakai rentang `[start, end)`. Definisi periode mana yang harus menjadi kontrak resmi?

### 8.2 Assumptions yang digunakan dalam dokumen ini

- Dokumen ini menggambarkan kemampuan **as-is**, bukan komitmen roadmap atau kesiapan produksi.
- `done` berarti alur tersedia di kode dan, bila tercakup, lulus unit/widget test; status ini tidak berarti printer, laci, MediaStore, atau upgrade database sudah lolos pengujian end-to-end pada perangkat nyata.
- `planned` hanya dipakai untuk QRIS yang eksplisit bertuliskan *Coming Soon*.
- File generated, cache IDE, dan output build tidak dipakai sebagai sumber requirement bisnis, kecuali ketika menunjukkan artifact APK/debug signing atau warning build yang nyata.
- Tidak ada asumsi tentang backend, cloud sync, multi-branch, atau platform selain Android karena implementasinya tidak ditemukan dalam repository ini.
