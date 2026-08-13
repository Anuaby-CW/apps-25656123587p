# Architecture

Dokumen ini menjelaskan boundary teknis aktual dan arah dependency yang diharapkan. Ia bukan klaim bahwa seluruh kode lama sudah ideal.

## Stack

- Flutter/Dart, Material 3, dan `flutter_localizations`.
- Riverpod untuk dependency composition dan state.
- Drift/SQLite untuk persistence offline.
- Firebase Core sebagai bootstrap opt-in melalui konfigurasi runtime lokal;
  belum menjadi sumber data operasional.
- Bluetooth thermal printer dan ESC/POS untuk struk/cash drawer.
- PDF, share, chart, image processing, intl, crypto, dan UUID.
- Android native Kotlin/Java 17 melalui `MethodChannel` untuk permission dan penyimpanan Downloads.

## Layer dan ownership

### `lib/core/`

Integrasi/platform service dan utility lintas fitur: printer, cash drawer, permission, file saver, routing, auth primitive, formatter struk, logging, config, dan helper.

Aturan: `core` tidak boleh bergantung pada presentation feature. Side effect platform harus memiliki error/timeout boundary yang jelas.

### `lib/data/`

Database Drift, table, migration, seed, DAO, concrete repository, dan implementasi persistence.

Aturan: query kompleks dimiliki DAO/repository yang sesuai. Transaction boundary ditempatkan sedekat mungkin dengan unit bisnis yang harus atomik.

### `lib/domain/`

Model, repository contract, pricing rule, dan use case orkestrasi.

Catatan aktual: layer ini belum sepenuhnya infrastructure-agnostic karena sebagian model/contract memakai record Drift dan beberapa use case bergantung pada abstraction `core`. Jangan memperluas coupling ini tanpa alasan. Refactor pemurnian layer harus menjadi task eksplisit, bukan efek samping fitur.

### `lib/presentation/`

Screen, dialog, feature widget, state presentation, dan composition root Riverpod.

`lib/presentation/providers/app_providers.dart` merangkai database, DAO, repository, use case, service, dan state global. Akses Drift langsung untuk shift/petty cash adalah exception lama.

### `lib/theme/`

Source of truth theme Flutter: color, typography, spacing, radius, layout breakpoint, role token, dan theme construction. Compatibility export lama tidak boleh menjadi lokasi implementasi baru.

### `lib/widgets/`

- `lib/widgets/common/`: komponen design-system lintas fitur.
- `lib/presentation/widgets/`: adapter/helper presentation yang tidak cocok sebagai primitive global.
- `lib/presentation/<feature>/widgets/`: komponen milik satu fitur.

## Dependency direction yang diinginkan

```text
presentation -> domain contracts/use cases -> data implementations
      |                 |                         |
      +-------------> core abstractions <---------+

theme/widgets common dapat dipakai presentation;
platform/native detail tetap di core/data atau Android host.
```

- Presentation tidak menulis SQL/Drift query baru secara langsung.
- Domain rule yang dapat diuji tanpa UI tidak diletakkan di widget.
- Data layer tidak menampilkan UI message atau mengakses `BuildContext`.
- Side effect printer/file/native tidak masuk transaction SQLite.

## Composition dan state

- Gunakan `Provider`, `FutureProvider`, `StreamProvider`, `Notifier`, atau `AsyncNotifier` sesuai lifecycle data.
- State lintas layar atau dependency service masuk composition root/provider feature.
- State sementara form, tab, filter lokal, animation controller, dan dialog boleh tetap lokal.
- Hindari provider global baru untuk state yang hanya hidup selama satu widget.
- Setelah mutation, invalidasi/refresh hanya provider yang benar-benar terdampak.

## Firebase foundation

- `lib/core/config/firebase_bootstrap.dart` memvalidasi konfigurasi compile-time
  sebelum menginisialisasi Firebase.
- Build tanpa konfigurasi Firebase harus tetap berjalan penuh dari Drift/SQLite.
- Konfigurasi parsial atau project ID selain `talaga-coffee-pos-20260730`
  ditolak sebelum inisialisasi agar aplikasi tidak diam-diam terhubung ke
  project Firebase yang salah.
- Nilai project-specific diberikan dari file lokal yang diabaikan Git melalui
  `--dart-define-from-file=firebase.runtime.json`; jangan commit nilai sebenarnya.
- `.firebaserc` mengikat repository ke project Firebase
  `talaga-coffee-pos-20260730`; app Android terdaftar dengan package
  `com.talagacoffee.pos`.
- Database Firestore `(default)` berada di region Jakarta `asia-southeast2`.
  `firebase.json` menunjuk ke `firestore.rules` dan `firestore.indexes.json`.
- Baseline `firestore.rules` deny-all sudah dideploy dan dibaca kembali dari
  project aktif. Database cloud tersedia, tetapi aplikasi belum memiliki izin
  read/write.
- Firebase Auth, mirror/sync, aturan akses terotorisasi, App Check, dan backend
  QRIS belum diaktifkan dan harus ditambahkan sebagai unit terpisah.

## Cross-cutting invariants

### Release signing

- Build release tidak boleh fallback ke debug signing.
- Konfigurasi signing hanya dibaca dari Gradle property atau environment
  variable eksternal; nilai lengkap dan keystore absolut wajib tersedia.
- APK release harus diverifikasi dengan `tool/verify_release_apk.ps1`; verifier
  mewajibkan `apksigner` sukses dan fingerprint signer cocok dengan nilai
  eksternal dari release record privat.
- Keystore harus berada di luar repository. Prosedur dan gate verifikasi berada
  di `docs/engineering/RELEASE_SIGNING.md`.

### Financial commit

Order, items, payment, transaction, dan stock impact untuk checkout tunai adalah satu unit bisnis. Commit terlebih dahulu; printer dan drawer sesudahnya.

### Historical snapshots

Order item/customer snapshot menjaga histori terhadap perubahan master. Jangan mengganti snapshot lama dengan live lookup tanpa migration dan keputusan produk.

### Role access

Navigation filter menjaga UX; operasi sensitif tetap memvalidasi role/invariant pada entry point data yang relevan.

### Native bridge

Perubahan nama `MethodChannel`, method, permission, atau payload harus sinkron di Dart, `MainActivity.kt`, manifest, dan test/manual verification.

## Referensi penting

- Entry point: `lib/main.dart`, `lib/app.dart`
- Shell/role: `lib/presentation/dashboard/dashboard_shell.dart`, `lib/core/routing/app_destination.dart`
- Composition: `lib/presentation/providers/app_providers.dart`
- Database: `lib/data/database/app_database.dart`
- Checkout: `lib/domain/usecases/checkout_usecase.dart`, `lib/data/repositories/checkout_repository.dart`
- Theme: `lib/theme/`, `lib/widgets/common/`
