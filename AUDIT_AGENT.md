# Audit `.agents/AGENT.md` — Talaga Coffee POS

Audit ini membandingkan `.agents/AGENT.md` dengan `README.md`, konfigurasi proyek, seluruh struktur `lib/`, integrasi Android, script di `tool/`, dan tujuh file pengujian di `test/`. Audit bersifat read-only terhadap `AGENT.md`.

## 1. Ringkasan Akurasi

Secara operasional, `AGENT.md` **cukup akurat**, tetapi **belum sepenuhnya representatif secara arsitektural**.

| Area | Hasil audit | Bukti utama |
| --- | --- | --- |
| Setup dan command utama | Akurat; kelima command sesuai dokumentasi dan konfigurasi. `flutter test` juga lulus 59 pengujian, sedangkan `flutter analyze` selesai tanpa masalah. | `README.md:120-136`, `pubspec.yaml:33-39`, `analysis_options.yaml` |
| Referensi file | Semua target yang disebut memang ada, tetapi seluruh URI `file:///c:/...` terikat ke mesin saat ini dan tidak portabel. | `.agents/AGENT.md:57,66,72,74,80-84` |
| Peta layer | Folder utamanya benar, tetapi klaim domain sebagai layer “murni” bertentangan dengan dependency aktual dan lokasi receipt formatter dipetakan keliru. | `lib/domain/models/order_models.dart:3`, `lib/domain/repositories/audit_repository_contract.dart:7-13`, `lib/core/printer/receipt_formatter_58mm.dart:8-88` |
| State dan UI | Riverpod memang tersentralisasi, tetapi tipe notifier, cakupan template halaman, token tema, dan konvensi bahasa digeneralisasi terlalu luas. | `lib/presentation/providers/app_providers.dart:43-782`, `lib/presentation/auth/login_screen.dart:44`, `lib/presentation/pos/pos_screen.dart:42-150` |
| Do/Don't | Sebagian besar memiliki dasar nyata, tetapi aturan transaksi dan kredensial perlu dikalibrasi terhadap exception yang benar-benar ada. | `lib/data/repositories/checkout_repository.dart:79-197`, `lib/core/constants/app_constants.dart:6-9` |
| Cakupan referensi | Belum memuat sumber konfigurasi, design system, native bridge, reset/seed, receive-payment, orders, asset generator, dan test suite. | `pubspec.yaml`, `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt`, `tool/prepare_logo_assets.dart`, `test/` |

Kesimpulannya, dokumen ini dapat dipakai sebagai orientasi awal, tetapi beberapa kalimat absolut berisiko mengarahkan agent ke pemahaman arsitektur yang tidak sesuai kode aktual.

## 2. Temuan: Command/Path Salah atau Tidak Valid

### 2.1 Tidak ada command utama yang invalid

Command pada `.agents/AGENT.md:20-37` sama dengan daftar resmi proyek di `README.md:123-127`:

- `flutter pub get`
- `dart run build_runner build`
- `flutter test`
- `flutter analyze`
- `flutter build apk --release`

Dependency pembangkit kode juga benar-benar tersedia melalui `drift_dev` dan `build_runner` di `pubspec.yaml:37-38`. Karena tidak ditemukan command yang salah, koreksi di bawah bersifat kelengkapan dan ketepatan cakupan.

### 2.2 Pemicu code generation terlalu sempit

`AGENT.md:26` hanya meminta regenerasi setelah perubahan tabel di `app_database.dart`. Proyek juga memakai `@DriftAccessor` di `lib/data/database/daos/reset_dao.dart:5-7`, yang menghasilkan `lib/data/database/daos/reset_dao.g.dart:1-6`. Dengan demikian, perubahan anotasi DAO juga memerlukan `dart run build_runner build`.

### 2.3 Informasi build release belum lengkap

Command build benar, tetapi catatan hanya menyebut debug signing. Output aktual yang didokumentasikan adalah `build/app/outputs/flutter-apk/app-release.apk` (`README.md:130-134`), dan konfigurasi release memang menunjuk debug signing di `android/app/build.gradle.kts:24-27`. `README.md:136` secara eksplisit melarang penggunaan konfigurasi ini untuk distribusi produksi sebelum signing resmi dipasang.

### 2.4 Link file tidak portabel

Link pada `.agents/AGENT.md:57,66,72,74,80-84` memakai URI absolut seperti `file:///c:/Users/Administrator/...`. Targetnya ada, tetapi link akan rusak ketika repository dipindahkan, dibuat worktree baru, atau dibuka pada OS/user lain. Dari lokasi `.agents/AGENT.md`, bentuk portabelnya adalah `../lib/...`, atau cukup tulis path repository dalam code span.

### 2.5 Referensi sumber kredensial tidak tepat

`AGENT.md:74` memberi kesan username/password default berasal dari `seed_data.dart`. Literal sumber sebenarnya berada di `lib/core/constants/app_constants.dart:6-9`; `lib/data/database/seed_data.dart:63-89` hanya membaca constant tersebut dan menyimpan hasil hash. Istilah “sesi default” juga tidak sesuai implementasi: yang dibuat adalah record akun bootstrap `user_admin` dan `user_kasir`.

## 3. Temuan: Generalisasi Berlebihan

### 3.1 “Beroperasi penuh tanpa internet” perlu dibatasi pada fitur aktif

Alur yang aktif memang lokal dan manifest utama bahkan tidak meminta permission `INTERNET` (`android/app/src/main/AndroidManifest.xml:1-8`). Namun `PaymentMethod.qris` sudah dimodelkan sebagai `QRIS (Coming Soon)` (`lib/domain/models/enums.dart:64-80`) dan sengaja diblokir di checkout (`lib/presentation/checkout/checkout_dialog.dart:80-84,426-436`). `api-dana.md:2-29` hanyalah indeks dokumentasi integrasi, bukan implementasi client DANA. Jadi klaim yang terverifikasi adalah **fitur aktif tidak bergantung backend**, bukan bahwa seluruh kapabilitas yang direncanakan dapat berjalan offline.

### 3.2 Domain bukan layer bisnis “murni”

Klaim pada `.agents/AGENT.md:11,47` tidak konsisten dengan dependency aktual:

- Model domain mengimpor record Drift melalui data layer: `lib/domain/models/order_models.dart:3` dan `lib/domain/models/session_models.dart:1`.
- Contract domain juga mengimpor `app_database.dart`, misalnya `lib/domain/repositories/audit_repository_contract.dart:7-13` dan `lib/domain/repositories/catalog_repository_contract.dart:4`.
- `lib/domain/usecases/report_export_usecase.dart:3-8` bergantung pada PDF dan file saver.
- Aturan bisnis juga berada di repository, misalnya `lib/data/repositories/orders_repository.dart:39-160` dan `lib/data/repositories/catalog_repository.dart:87-205`.
- Shift dan petty cash memuat data access serta validasi langsung di provider, yaitu `lib/presentation/providers/app_providers.dart:572-758`.

Selain itu, receipt formatting bukan tanggung jawab domain. `lib/domain/usecases/receipt_usecase.dart:3-20` hanya mengorkestrasi service, sedangkan encoder ESC/POS berada di `lib/core/printer/receipt_formatter_58mm.dart:8-88` dan `lib/core/printer/receipt_formatter_80mm.dart:8-124`.

### 3.3 Riverpod tidak memakai `StateNotifier`

`AGENT.md:12` menyebut “state notifier/async notifier”, tetapi tidak ditemukan penggunaan `StateNotifier`. Implementasi memakai `Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, `AsyncNotifier`, `NotifierProvider`, dan `AsyncNotifierProvider` di `lib/presentation/providers/app_providers.dart:43-49,188-247,355-529,569-782`. State sementara tetap dikelola lokal dengan `ConsumerStatefulWidget`/`setState`, misalnya filter pada `lib/presentation/orders/orders_screen.dart:21-31,71`.

### 3.4 `AppPageFrame` dan `AppPageHeader` bukan template universal

Sebelas dari empat belas file yang mendeklarasikan screen memakai kedua komponen, sehingga polanya nyata untuk halaman konten standar. Namun ada layout yang sengaja berbeda:

- Login memakai `Scaffold` langsung: `lib/presentation/auth/login_screen.dart:44-101`.
- POS memakai workspace operasional khusus: `lib/presentation/pos/pos_screen.dart:42-150`.
- Orders memakai `LayoutBuilder` dan header manual: `lib/presentation/orders/orders_screen.dart:36-50`.

Karena itu, kewajiban “halaman baru” pada `.agents/AGENT.md:66` terlalu luas jika juga mencakup login, shell, fullscreen dialog, atau workspace operasional.

### 3.5 Larangan literal tema belum konsisten di seluruh project

Mayoritas UI memang memakai token `lib/theme/`, tetapi kata “Selalu” pada `.agents/AGENT.md:64` tidak mencerminkan exception aktual:

- Warna literal: `lib/presentation/pos/shift_reconciliation_dialog.dart:119,345-346,378,682`, `lib/presentation/pos/pos_screen.dart:993`, dan `lib/presentation/settings/widgets/reset_data_admin_panel.dart:126,264`.
- Spacing literal: `lib/presentation/pos/pos_screen.dart:519,531`.
- Dimensi tipografi literal: `lib/presentation/cart/cart_panel.dart:263` dan `lib/presentation/checkout/checkout_dialog.dart:437,506,569`.

Token Flutter juga tidak dapat diterapkan langsung pada widget PDF `pw.*`, contohnya `lib/presentation/pos/shift_reconciliation_dialog.dart:709-784`. Aturan perlu dibingkai sebagai standar untuk kode Flutter baru/yang disentuh, dengan pengecualian eksplisit untuk renderer PDF dan nilai khusus.

### 3.6 Bahasa UI dan identifier tidak sepenuhnya mengikuti pembagian Indonesia/Inggris

Counterexample teks UI pada `.agents/AGENT.md:65` meliputi:

- `Orders` dan `ticket`: `lib/presentation/orders/orders_screen.dart:50,86`.
- `Settings`: `lib/presentation/dashboard/dashboard_shell.dart:197`.
- `printer logs`: `lib/presentation/settings/widgets/reset_data_admin_panel.dart:91`.
- `Coming Soon`: `lib/presentation/checkout/checkout_dialog.dart:426`.

Sejumlah istilah operasional juga sengaja dipertahankan, seperti `Hot`/`Ice` (`lib/presentation/pos/pos_screen.dart:690-691`) serta `Dine In`, `Take Away`, `Add-on`, dan `Manual Brew` pada alur POS/checkout.

Identifier mayoritas berbahasa Inggris, tetapi bukan tanpa exception: `BukaShiftOverlay`, `TutupShiftDialog`, dan `showTutupShiftDialog` berada di `lib/presentation/pos/shift_reconciliation_dialog.dart:22,30-37,188-195`; `_RacikanWorkspace` dan `_RacikanSwitcher` berada di `lib/presentation/beans/beans_screen.dart:110-156`.

### 3.7 Aturan transaksi perlu berorientasi pada invariant, bukan jumlah tabel

Aturan `.agents/AGENT.md:63` memiliki dasar kuat: checkout/payment memakai transaction (`lib/data/repositories/checkout_repository.dart:79-197,210-272`), pembatalan dan reversal stok memakai transaction (`lib/data/repositories/orders_repository.dart:81-160`), dan reset/seed juga atomic (`lib/data/repositories/reset_repository.dart:18-28`, `lib/data/database/seed_data.dart:27-60`).

Namun implementasi menunjukkan bahwa “semua operasi beberapa tabel” bukan deskripsi konsisten:

- Mutasi produk selesai dalam transaction, lalu audit ditulis sesudahnya di tabel lain: `lib/data/repositories/catalog_repository.dart:128-191`.
- Connect printer menulis setting, printer log, dan audit secara berurutan tanpa satu transaction bersama: `lib/presentation/settings/settings_screen.dart:550-581`.
- Lima setting outlet ditulis sebagai lima upsert terpisah: `lib/data/repositories/settings_repository.dart:27-39`.

Sebaliknya, beberapa row pada satu tabel juga dapat membentuk satu unit bisnis. Rumusan yang sesuai kode inti adalah menjaga operasi database yang memiliki invariant *all-or-nothing*, lalu memisahkan printer, drawer, file export/share, dan side effect platform dari transaction.

### 3.8 `app_providers.dart` bukan sekadar tempat “state global”

`AGENT.md:57` terlalu menyederhanakan peran file tersebut. `lib/presentation/providers/app_providers.dart:43-185` adalah composition root untuk database, DAO, repository, use case, dan service. File yang sama juga memuat query/mutasi Drift langsung untuk shift dan petty cash di `lib/presentation/providers/app_providers.dart:572-758`. Pola umum repository-contract memang ada, tetapi akses DB langsung tersebut adalah exception aktual yang perlu diketahui agent agar tidak keliru menyebut arsitekturnya seragam.

## 4. Temuan: Gap / Terlewat

### 4.1 Prasyarat toolchain dan working directory

Semua command mengandalkan root repository, terutama `tool/prepare_logo_assets.dart:6-12` dan path aset dalam `test/logo_assets_test.dart:9,22,44-46`. Versi minimum yang terkunci juga tidak disebut:

- Dart `^3.12.2`: `pubspec.yaml:6-7`.
- Flutter `>=3.44.0`: `pubspec.lock:1133-1135`.
- Java/Kotlin JVM 17: `android/app/build.gradle.kts:11-14,31-34`.
- Gradle 9.1.0: `android/gradle/wrapper/gradle-wrapper.properties:5`.

### 4.2 Workflow aset/logo dan launcher icon

`tool/prepare_logo_assets.dart:6-9,63-106` menghasilkan logo master, foreground adaptive, logo termal, dan splash Android per density. Launcher icon kemudian dikonfigurasi melalui `flutter_launcher_icons` di `pubspec.yaml:39,47-53`. Workflow ini tidak disebut sama sekali, padahal file outputnya dipakai aplikasi dan diuji oleh `test/logo_assets_test.dart` serta `test/receipt_logo_test.dart`.

### 4.3 Generated/local artifacts selain `.g.dart`

Larangan edit hanya menyebut `.g.dart`, padahal ada artifact generated/local lain:

- `.flutter-plugins-dependencies`, diabaikan oleh `.gitignore:30`.
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`, bertanda generated pada baris 9-12 dan diabaikan oleh `android/.gitignore:7`.
- `android/local.properties`, diabaikan oleh `android/.gitignore:6`.
- Output `build/`, diabaikan oleh `.gitignore:33`.

### 4.4 Perbedaan `schemaVersion` dan `seed_version`

AGENT hanya membahas `schemaVersion = 5`. Proyek juga punya versi seed tersendiri, `seed_version = 2`, melalui `lib/data/database/seed_data.dart:15-40`. Keduanya tidak boleh diperlakukan sama: `schemaVersion` mengatur struktur/migrasi Drift (`lib/data/database/app_database.dart:347-368`), sedangkan `seed_version` mengontrol bootstrap/lokalisasi data bawaan.

Database saat ini mendaftarkan 21 tabel di `lib/data/database/app_database.dart:317-340`. Walaupun `PRAGMA foreign_keys = ON` dijalankan pada `lib/data/database/app_database.dart:369-371`, deklarasi tabel tidak memakai `.references(...)`; hubungan antar-record saat ini dijaga secara logis/manual. Batas ini penting dan belum tercatat.

### 4.5 Struktur widget tiga tingkat

Peta folder belum membedakan:

- Shared design-system components di `lib/widgets/common/`, misalnya `app_page_frame.dart` dan `app_status_badge.dart`.
- Adapter presentasi di `lib/presentation/widgets/`, misalnya `async_state_view.dart`, `empty_state.dart`, dan `status_chip.dart`.
- Widget lokal fitur di `lib/presentation/settings/widgets/`.

Tanpa penjelasan ini, agent dapat menaruh komponen baru pada layer widget yang salah walaupun struktur nyata proyek sudah membedakan ketiganya.

### 4.6 Scope role guard

`AppDestination.isAllowed()` hanya memfilter menu/navigation client-side (`lib/core/routing/app_destination.dart:27-38`; `lib/presentation/dashboard/dashboard_shell.dart:39,608`). Sebagian repository manajemen tidak memeriksa role pemanggil. Dengan arsitektur lokal tanpa backend, filter route tersebut tidak boleh didokumentasikan seolah-olah merupakan boundary otorisasi yang berdiri sendiri.

### 4.7 Hardcoded identity seed

AGENT membahas username/password, tetapi tidak menyebut ID akun seed. Record kasir dibuat dengan ID `user_kasir` di `lib/data/database/seed_data.dart:78-89`, dan UI settings melakukan lookup menggunakan literal yang sama di `lib/presentation/settings/settings_screen.dart:97,495`. Ini adalah coupling penting untuk alur reset/default user dan konfigurasi nama kasir.

### 4.8 Native bridge dan permission Android

Dua MethodChannel wajib sinkron antara Dart dan Kotlin:

- Downloads: `lib/core/files/report_file_saver.dart:9` ↔ `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt:20,31-51`.
- Bluetooth permission: `lib/core/permissions/bluetooth_permission_service.dart:26` ↔ `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt:21-22,52-69`.

Permission terkait berada di `android/app/src/main/AndroidManifest.xml:2-8`. Tidak satu pun file native ini masuk daftar referensi penting saat ini.

### 4.9 Referensi bisnis, design system, dan pengujian belum lengkap

Bagian referensi penting melewatkan setidaknya:

- Setup/config: `README.md`, `pubspec.yaml`, `analysis_options.yaml`, `android/app/build.gradle.kts`.
- Auth/bootstrap: `lib/core/auth/password_hasher.dart`, `lib/core/constants/app_constants.dart`, `lib/data/database/seed_data.dart`.
- Database/reset: `lib/data/database/daos/reset_dao.dart`, `lib/data/repositories/reset_repository.dart`.
- Alur finansial/order: `lib/domain/usecases/receive_payment_usecase.dart`, `lib/data/repositories/orders_repository.dart`.
- Reports/file: `lib/domain/usecases/report_export_usecase.dart`, `lib/core/files/report_file_saver.dart`.
- Printer: `lib/core/printer/printer_service.dart`, `lib/core/printer/android_bluetooth_printer_service.dart`, dan kedua receipt formatter.
- Shell/design system: `lib/presentation/dashboard/dashboard_shell.dart`, `lib/theme/app_theme.dart`, `lib/theme/app_role_tokens.dart`, `lib/theme/app_layout.dart`, `lib/theme/app_spacing.dart`, `lib/theme/app_typography.dart`, serta `lib/widgets/common/`.
- Regression suite: tujuh file pada `test/`, terutama `test/pos_business_rules_test.dart`, `test/catalog_integrity_test.dart`, `test/data_management_access_test.dart`, dan `test/receipt_logo_test.dart`.

## 5. Rekomendasi Revisi

Blok berikut dapat langsung ditempel untuk mengganti atau melengkapi bagian terkait di `.agents/AGENT.md`.

### 5.1 Ganti `Project Overview`

```markdown
## 1. Project Overview

Talaga Coffee POS adalah aplikasi kasir *offline-first* untuk ponsel dan tablet Android. Seluruh alur yang saat ini aktif—login lokal, katalog, checkout tunai, pesanan, stok, dan laporan—menggunakan SQLite lokal dan tidak bergantung pada backend. QRIS/integrasi pembayaran online belum aktif.

* **Core**: Integrasi printer termal Bluetooth, *cash drawer*, permission Android, file export, dan formatter struk ESC/POS 58 mm/80 mm.
* **Data Layer**: Drift/SQLite untuk persistence lokal, DAO, concrete repository, migrasi, dan seed/reset data.
* **Domain-oriented Layer**: Model, repository contract, pricing, dan use case orkestrasi. Layer ini belum sepenuhnya infrastructure-agnostic karena sejumlah model/contract memakai record Drift dan beberapa use case memakai abstraction dari `core/`. Aturan bisnis saat ini tersebar di use case, repository, dan provider shift/petty cash.
* **Presentation**: Flutter Material 3 dengan Riverpod (`Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, dan `AsyncNotifier`) serta workspace Admin dan Kasir.
```

### 5.2 Ganti/lengkapi `Setup & Commands`

````markdown
## 2. Setup & Commands

Jalankan seluruh command dari root repository. Toolchain yang terkunci saat ini: Dart `^3.12.2`, Flutter `>=3.44.0`, Java/Kotlin JVM 17, dan Gradle 9.1.0.

```bash
flutter pub get
dart run build_runner build
flutter test
flutter analyze
flutter build apk --release
```

Jalankan `dart run build_runner build` setelah mengubah table declaration, daftar/anotasi `@DriftDatabase`, atau DAO beranotasi `@DriftAccessor`. Jangan edit `app_database.g.dart` atau `reset_dao.g.dart` secara manual.

Jika sumber logo berubah, jalankan dari root:

```bash
dart run tool/prepare_logo_assets.dart
dart run flutter_launcher_icons
```

Script pertama menghasilkan logo aplikasi, foreground adaptive, logo termal, dan splash Android. Command kedua memakai konfigurasi `flutter_launcher_icons` di `pubspec.yaml`.

APK release dihasilkan di `build/app/outputs/flutter-apk/app-release.apk`. Konfigurasi release saat ini masih memakai debug signing; jangan distribusikan ke produksi/Play Store sebelum signing resmi dikonfigurasi.
````

### 5.3 Ganti/lengkapi `Struktur & Konvensi`

```markdown
## 3. Struktur & Konvensi

* `lib/core/`: Integration/service platform, printer/drawer, permission, file saver, routing, formatter struk, dan utility.
* `lib/data/`: Drift database, migrasi, seed, DAO, dan concrete repository.
* `lib/domain/`: Model, repository contract, dan use case orkestrasi. Perhatikan bahwa sejumlah model/contract saat ini masih bergantung pada record Drift; jangan menyebut layer ini pure atau sepenuhnya independen dari data/core.
* `lib/presentation/`: Screen per fitur, composition root Riverpod, dan widget presentasi.
* `lib/theme/`: Source of truth design system dan theme berbasis role. `lib/core/theme/app_theme.dart` hanya compatibility export.
* `lib/widgets/common/`: Shared design-system components lintas fitur.
* `lib/presentation/widgets/`: Adapter/helper presentasi.
* `lib/presentation/<feature>/widgets/`: Widget yang hanya dimiliki satu fitur.

Nama file memakai `lower_case_with_underscores.dart`, class memakai `UpperCamelCase`, dan class tabel Drift memakai nama jamak. Concrete repository di `lib/data/repositories/` mengimplementasikan contract terkait di `lib/domain/repositories/`.

`lib/presentation/providers/app_providers.dart` adalah composition root untuk database, DAO, repository, use case, service, dan state global. File ini juga memiliki exception akses Drift langsung untuk shift dan petty cash; jangan menganggap exception tersebut sebagai pola yang berlaku di seluruh layer. State sementara form, filter, dialog, dan animasi boleh tetap lokal melalui `ConsumerStatefulWidget`/`setState`.

Halaman konten standar memakai `AppPageFrame` dan `AppPageHeader`. Login, shell, fullscreen dialog, atau workspace operasional khusus seperti POS dapat memakai layout khusus. `OrdersScreen` saat ini juga memakai header/layout manual.
```

### 5.4 Ganti `Do's`

```markdown
## 4. Do's (Hal yang Harus Diikuti)

* **Jaga Atomicity Invariant Database**: Write lokal yang membentuk satu unit bisnis *all-or-nothing* harus berada dalam satu transaction Drift, baik menyentuh beberapa tabel maupun beberapa row pada tabel yang sama. Jangan memasukkan printer, cash drawer, export/share file, atau side effect platform ke transaction database.
* **Commit Dahulu, Periferal Sesudahnya**: Simpan transaksi finansial/state utama lebih dahulu. Jalankan printer dan cash drawer setelah commit, dengan timeout serta penanganan error tersendiri. Kegagalan periferal tidak boleh dilaporkan seolah-olah commit database ikut gagal.
* **Gunakan Design System Flutter**: Untuk kode Flutter baru atau yang diubah, gunakan `Theme.of(context)`, `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, dan `AppLayout` untuk nilai berulang. Renderer PDF `pw.*` dan nilai khusus sekali-pakai adalah exception karena tidak memakai widget/token Flutter secara langsung.
* **Gunakan Bahasa UI yang Konsisten**: Navigasi, judul, aksi, status, validasi, dan pesan menggunakan Bahasa Indonesia. Istilah merek/protokol/operasional yang sudah dipakai—misalnya QRIS, Bluetooth, ESC/POS, PDF, Instagram, Manual Brew, Hot/Ice, Add-on, dan Dine In/Take Away—boleh dipertahankan; jangan sisakan English incidental seperti `Orders`, `Settings`, `ticket`, `printer logs`, atau `Coming Soon`.
* **Gunakan Identifier Inggris untuk Kode Baru**: `BukaShiftOverlay`, `TutupShiftDialog`, `showTutupShiftDialog`, `_RacikanWorkspace`, dan `_RacikanSwitcher` adalah exception yang sudah ada, bukan pola penamaan baru.
```

### 5.5 Ganti/lengkapi `Don't / Area Sensitif`

```markdown
## 5. Don't / Area Sensitif

* **Jangan Edit Artifact Generated/Local**: Jangan edit `.g.dart`, `.flutter-plugins-dependencies`, `GeneratedPluginRegistrant.java`, `android/local.properties`, atau output `build/` secara manual. Regenerasi melalui tool yang sesuai.
* **Schema dan Migrasi Drift**: Schema saat ini versi 5 dengan 21 tabel. Perubahan schema untuk instalasi lama harus memperbarui table declaration/daftar `@DriftDatabase`, menaikkan `schemaVersion`, menambah jalur `onUpgrade` untuk versi lama yang didukung, lalu meregenerasi `.g.dart`. `PRAGMA foreign_keys = ON` tidak berarti relasi sudah enforced karena schema saat ini tidak memakai `.references(...)`.
* **Bedakan Schema Version dan Seed Version**: `schemaVersion` mengatur struktur database; `seed_version` (saat ini `2`) mengatur bootstrap/lokalisasi data bawaan. Perubahan katalog/default setting harus mengevaluasi `SeedData.ensureSeeded()` dan reset katalog, bukan otomatis menaikkan schema version.
* **Jangan Menduplikasi Kredensial/Identity Default**: Sumber username/password bootstrap saat ini adalah `AppConstants`; `SeedData` menyimpan password sebagai hash. Jangan menyalin literal `admin`, `kasir`, `123456`, `user_admin`, atau `user_kasir` ke file baru. Perubahan default tidak otomatis memigrasikan instalasi existing dan harus mempertimbangkan seed/reset serta lookup akun di Settings.
* **Role Guard**: `AppDestination.isAllowed()` adalah filter menu/navigation client-side, bukan boundary keamanan backend. Pertahankan pengecekan role pada entry point UI dan validasi invariant pada operasi data yang relevan.
* **QRIS/DANA Belum Terimplementasi**: `PaymentMethod.qris` dan `api-dana.md` hanya menandai rencana/referensi. Jangan menganggap adanya client API, credential merchant, webhook, atau alur settlement di kode saat ini.
* **Sinkronkan Native Bridge**: Nama channel/method Downloads dan Bluetooth permission harus tetap sama antara service Dart, `MainActivity.kt`, dan permission di `AndroidManifest.xml`.
```

### 5.6 Ganti `Referensi File Penting`

```markdown
## 6. Referensi File Penting

* **Setup/config**: `README.md`, `pubspec.yaml`, `analysis_options.yaml`, `android/app/build.gradle.kts`.
* **Entry point/shell/role**: `lib/main.dart`, `lib/app.dart`, `lib/presentation/dashboard/dashboard_shell.dart`, `lib/core/routing/app_destination.dart`.
* **Auth/bootstrap**: `lib/core/auth/password_hasher.dart`, `lib/core/constants/app_constants.dart`, `lib/data/database/seed_data.dart`.
* **Database/migrasi/reset**: `lib/data/database/app_database.dart`, `lib/data/database/daos/reset_dao.dart`, `lib/data/repositories/reset_repository.dart`.
* **Checkout/payment/order**: `lib/domain/usecases/checkout_usecase.dart`, `lib/domain/usecases/receive_payment_usecase.dart`, `lib/data/repositories/checkout_repository.dart`, `lib/data/repositories/orders_repository.dart`.
* **Reports/file export**: `lib/domain/usecases/report_export_usecase.dart`, `lib/core/files/report_file_saver.dart`.
* **Printer/drawer**: `lib/core/printer/printer_service.dart`, `lib/core/printer/android_bluetooth_printer_service.dart`, `lib/core/printer/receipt_formatter_58mm.dart`, `lib/core/printer/receipt_formatter_80mm.dart`, `lib/core/printer/cash_drawer_service.dart`.
* **Native Android**: `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`.
* **Riverpod composition root**: `lib/presentation/providers/app_providers.dart`.
* **Design system**: `lib/theme/app_theme.dart`, `lib/theme/app_role_tokens.dart`, `lib/theme/app_layout.dart`, `lib/theme/app_spacing.dart`, `lib/theme/app_typography.dart`, `lib/theme/app_colors.dart`, dan `lib/widgets/common/`.
* **Asset generation**: `tool/prepare_logo_assets.dart`, konfigurasi `flutter_launcher_icons` di `pubspec.yaml`.
* **Regression tests**: seluruh file pada `test/`, terutama `pos_business_rules_test.dart`, `catalog_integrity_test.dart`, `data_management_access_test.dart`, `theme_design_system_test.dart`, `logo_assets_test.dart`, dan `receipt_logo_test.dart`.
```
