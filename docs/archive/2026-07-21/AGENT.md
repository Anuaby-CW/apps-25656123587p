# AGENT.md — Talaga Coffee POS (Flutter)

Dokumen ini adalah instruksi standar dan acuan utama bagi AI coding agent saat bekerja di repositori **Talaga Coffee POS**.

---

## 1. Project Overview
Talaga Coffee POS adalah aplikasi kasir (*Point of Sale*) *offline-first* khusus ponsel dan tablet Android. Aplikasi ini beroperasi penuh tanpa koneksi internet dengan memanfaatkan SQLite lokal.
* **Core**: Integrasi periferal Bluetooth printer termal, *cash drawer*, dan sistem permission Android native.
* **Data Layer**: Drift ORM (SQLite) untuk persistence lokal, beserta DAO terpisah untuk query spesifik.
* **Domain Layer**: Model data, contracts (repositori), dan *use cases* bisnis murni (checkout, receipt formatting, pricing).
* **Presentation**: Flutter Material 3, dikelola dengan Riverpod (state notifier/async notifier) dan struktur visual yang terbagi per role (Admin & Kasir).

---

## 2. Setup & Commands
Gunakan perintah standard Flutter berikut untuk pengembangan dan pengujian:
* **Inisialisasi & Ambil Dependency**:
  ```bash
  flutter pub get
  ```
* **Code Generation (Drift database & model)**:
  ```bash
  dart run build_runner build
  ```
  *(Jalankan perintah ini setiap kali ada perubahan pada tabel di `lib/data/database/app_database.dart`)*
* **Menjalankan Pengujian Lokal**:
  ```bash
  flutter test
  ```
* **Menganalisis Kode (Static Analysis)**:
  ```bash
  flutter analyze
  ```
* **Build APK Release (Android)**:
  ```bash
  flutter build apk --release
  ```
  *(Catatan: Build release saat ini masih dikonfigurasi menggunakan debug signing)*

---

## 3. Struktur & Konvensi
* **Peta Folder Utama**:
  * `lib/core/`: Driver periferal printer/drawer, authorization route, file utility, permission service.
  * `lib/data/`: Implementasi konkret repository, tabel SQLite database (`app_database.dart`), dan Data Access Objects (`lib/data/database/daos/`).
  * `lib/domain/`: Logika bisnis murni (models, repository contracts, use cases).
  * `lib/presentation/`: Screen per modul, provider Riverpod (`app_providers.dart`), dan widget halaman.
  * `lib/theme/`: Pusat desain sistem (warna, tipografi, radius, spacing, bayangan).
  * `lib/widgets/`: Widget umum yang digunakan ulang di berbagai layar.
* **Konvensi Penamaan**:
  * Nama file: `lower_case_with_underscores.dart`.
  * Nama class: `UpperCamelCase`.
  * Penamaan tabel Drift: Mengikuti class tabel jamak (misal: `Users`, `Products`).
  * File repository konkret di `data/` harus mengimplementasikan contract repository dari `domain/repositories/` (misal: `CatalogRepository` mengimplementasikan `CatalogRepositoryContract`).
* **State Management**:
  * Gunakan Riverpod. Kelola state global di file sentral [app_providers.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/presentation/providers/app_providers.dart).
  * Widget layar mengonsumsi state via `ConsumerWidget` atau `ConsumerStatefulWidget`.

---

## 4. Do's (Hal yang Harus Diikuti)
* **Gunakan Transaksi Database**: Seluruh operasi penulisan yang melibatkan beberapa tabel secara bersamaan (misalnya checkout yang mengurangi stok dan menyimpan order) wajib dibungkus dalam blok `transaction` Drift.
* **Pusatkan Token Tema**: Hindari menulis nilai warna atau spacing secara literal di komponen UI screen. Selalu gunakan `Theme.of(context)` atau import token dari `lib/theme/` (`AppColors`, `AppSpacing`, `AppRadius`, dll.).
* **Bahasa UI Konsisten**: Teks visual untuk pengguna akhir harus berbahasa Indonesia (kasir-friendly). Kode program (variabel, class, method) harus berbahasa Inggris.
* **Gaya Komponen UI**: Halaman baru harus menggunakan template [AppPageFrame](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/widgets/common/app_page_frame.dart) and [AppPageHeader](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/widgets/common/app_page_header.dart) untuk konsistensi layout.

---

## 5. Don't / Area Sensitif
* **Jangan Edit File Generated Secara Manual**: File berakhiran `.g.dart` (seperti `app_database.g.dart` dan `reset_dao.g.dart`) dibuat otomatis oleh build runner. Lakukan regenerasi via command line.
* **Jangan Mengubah `schemaVersion` Tanpa Migrasi**: Versi database saat ini adalah `schemaVersion = 5`. Jika Anda mengubah atau menambah tabel di [app_database.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/data/database/app_database.dart), Anda harus memperbarui `schemaVersion` dan mendefinisikan langkah migrasi di blok `onUpgrade`.
* **Jangan Biarkan Masalah Periferal Membatalkan Transaksi**: Kegagalan printer termal atau cash drawer tidak boleh membatalkan pencatatan finansial transaksi di database lokal.
* **Jangan Hardcode Username/Password**: Sesi default admin (`admin` / `123456`) dan kasir (`kasir` / `123456`) di-seed secara terpusat melalui [seed_data.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/data/database/seed_data.dart).

---

## 6. Referensi File Penting
Sebelum bekerja pada fitur tertentu, pelajari file kunci berikut:
* **Entry Point**: [main.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/main.dart) & [app.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/app.dart)
* **Definisi Database**: [app_database.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/data/database/app_database.dart) & [seed_data.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/data/database/seed_data.dart)
* **Logika Checkout**: [checkout_usecase.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/domain/usecases/checkout_usecase.dart) & [checkout_repository.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/data/repositories/checkout_repository.dart)
* **State & Providers**: [app_providers.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/presentation/providers/app_providers.dart)
* **Routing & Otorisasi**: [app_destination.dart](file:///c:/Users/Administrator/Videos/New%20folder/talaga_coffee_pos/lib/core/routing/app_destination.dart)
