# Repository Instructions — Talaga Coffee POS

Dokumen ini adalah entry point instruksi permanen untuk coding agent yang bekerja di repository ini. Baca hanya dokumen yang relevan dengan tugas agar konteks tetap fokus.

## Urutan sumber kebenaran

Jika ada konflik, gunakan urutan berikut:

1. Permintaan pengguna pada task saat ini.
2. `AGENTS.md` ini untuk aturan engineering permanen.
3. `PRD.md` dan `docs/product/REQUIREMENTS.md` untuk keputusan produk aktif.
4. `FEATURES.md` untuk status fitur aktif.
5. `DEACTIVATED_FEATURES.md` dan `docs/features/FEATURE_FLAGS.md` untuk fitur yang diparkir.
6. `DESIGN.md` dan token aktual di `lib/theme/` untuk keputusan visual.
7. Kode dan test yang sedang berjalan untuk kondisi implementasi aktual.

Jangan mengaktifkan requirement yang masih berupa pertanyaan terbuka. Catat konflik dokumentasi yang ditemukan dan perbarui dokumen terkait dalam perubahan yang sama.

## Konteks proyek

Talaga Coffee POS adalah aplikasi kasir Flutter offline-first untuk ponsel dan tablet Android. Alur aktif—login lokal, katalog, shift, checkout tunai, stok, transaksi, laporan, dan pengaturan—menggunakan Drift/SQLite lokal. QRIS/DANA, cloud sync, dan backend belum menjadi kapabilitas aktif.

Workspace dibagi berdasarkan role:

- Kasir: shift, POS, checkout tunai, petty cash, printer, dan cash drawer.
- Admin: dashboard, transaksi, laporan, katalog, stok, pengguna, audit, identitas outlet, dan reset data.

## Peta konteks berdasarkan tugas

| Ketika mengerjakan | Baca lebih dulu |
|---|---|
| Menentukan scope atau perilaku produk | `PRD.md`, `docs/product/REQUIREMENTS.md`, `docs/product/USER_FLOWS.md` |
| Menambah atau mengubah fitur | `FEATURES.md`, `docs/engineering/FEATURE_MAP.md`, requirement terkait |
| Menyentuh fitur nonaktif | `DEACTIVATED_FEATURES.md`, `docs/features/FEATURE_FLAGS.md` |
| Mengubah UI/theme/layout | `DESIGN.md`, `lib/theme/`, `docs/engineering/ENGINEERING_RULES.md` |
| Mengubah database atau persistence | `docs/engineering/DATA_MODEL.md`, `lib/data/database/app_database.dart` |
| Menyentuh arsitektur/provider/repository | `docs/engineering/ARCHITECTURE.md`, `docs/engineering/ENGINEERING_RULES.md` |
| Menyiapkan atau memverifikasi perubahan | `docs/quality/TESTING.md`, `docs/quality/DEFINITION_OF_DONE.md` |
| Membutuhkan prompt tugas terstruktur | `docs/prompts/IMPLEMENT_FEATURE.md` |

## Commands

Jalankan dari root repository:

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release
```

Jalankan `dart run build_runner build` setelah mengubah deklarasi table, daftar/anotasi `@DriftDatabase`, atau DAO beranotasi `@DriftAccessor`. Jangan edit file generated secara manual.

Jika sumber logo berubah:

```powershell
dart run tool/prepare_logo_assets.dart
dart run flutter_launcher_icons
```

Build release saat ini masih memakai debug signing dan belum boleh dianggap siap distribusi produksi.

## Aturan implementasi

- Pelajari alur yang ada sebelum mengubah kode. Jangan membuat abstraction baru bila pola lokal yang sesuai sudah tersedia.
- Pertahankan pembagian `core/`, `data/`, `domain/`, `presentation/`, `theme/`, dan `widgets/` sebagaimana dijelaskan di `docs/engineering/ARCHITECTURE.md`.
- Gunakan Riverpod sesuai pola lokal. `app_providers.dart` adalah composition root; akses Drift langsung untuk shift/petty cash adalah exception lama, bukan pola umum baru.
- Write yang membentuk satu unit bisnis all-or-nothing harus berada dalam satu transaction Drift.
- Commit data finansial lebih dahulu; jalankan printer, cash drawer, export, atau share setelah commit. Kegagalan periferal tidak boleh membatalkan transaksi yang sudah tersimpan.
- Untuk Flutter UI baru/diubah, gunakan `Theme.of(context)` dan token di `lib/theme/`. Jangan menambah warna, spacing, radius, atau typography berulang secara literal.
- Teks UI menggunakan Bahasa Indonesia. Identifier kode baru menggunakan Bahasa Inggris, kecuali istilah domain/merek yang memang dipertahankan.
- Gunakan shared widget hanya untuk pola yang benar-benar lintas fitur. Widget khusus fitur tetap berada di folder fitur terkait.
- Pertahankan role guard pada UI dan validasi invariant pada operasi data. Filter navigasi bukan boundary keamanan backend.
- Jangan menganggap `api-dana.md`, enum QRIS, schema lama, provider, atau test kompatibilitas sebagai bukti bahwa fitur tersebut aktif.

## Area sensitif

- Jangan edit `.g.dart`, `.flutter-plugins-dependencies`, `GeneratedPluginRegistrant.java`, `android/local.properties`, atau output `build/` secara manual.
- Schema saat ini versi 5. Perubahan schema harus memiliki migrasi, kenaikan `schemaVersion`, regenerasi, serta test upgrade yang relevan.
- `schemaVersion` dan `seed_version` memiliki fungsi berbeda; jangan menaikkan salah satunya tanpa alasan yang sesuai.
- Jangan menduplikasi username, password, atau ID akun bootstrap. Gunakan sumber yang sudah ada di `AppConstants` dan `SeedData`.
- Jaga nama channel/method tetap sinkron antara Dart, `MainActivity.kt`, dan `AndroidManifest.xml`.
- Fitur yang default-nya nonaktif hanya boleh diaktifkan melalui keputusan scope eksplisit dan verifikasi di `docs/features/FEATURE_FLAGS.md`.
- Jangan menghapus kompatibilitas data lama tanpa migration/cleanup plan dan persetujuan eksplisit.

## Workflow wajib

Untuk task implementasi:

1. Nyatakan objective, acceptance criteria, dan bagian yang di luar scope.
2. Baca dokumen serta kode yang relevan saja.
3. Buat perubahan terkecil yang menyelesaikan requirement.
4. Tambahkan atau perbarui test untuk perilaku yang berubah.
5. Jalankan formatter, analysis, dan test yang proporsional.
6. Perbarui source of truth bila status/behavior fitur berubah.
7. Laporkan file yang berubah, hasil verifikasi, asumsi, dan risiko yang tersisa.

Definition of Done lengkap berada di `docs/quality/DEFINITION_OF_DONE.md`.

