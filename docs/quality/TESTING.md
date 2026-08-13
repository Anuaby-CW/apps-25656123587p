# Testing and Verification

## Quality commands

Jalankan dari root repository:

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Tambahkan `dart run build_runner build` sebelum analysis/test jika deklarasi Drift/DAO berubah. Build APK hanya diperlukan untuk perubahan packaging, dependency/native Android, asset, atau release candidate.

## Test inventory

| File | Fokus utama |
|---|---|
| `test/pos_business_rules_test.dart` | Checkout, report, stock, user, dan aturan bisnis POS |
| `test/catalog_integrity_test.dart` | Referensi dan delete invariant katalog |
| `test/data_management_access_test.dart` | Role/konfirmasi/reset data |
| `test/feature_flags_test.dart` | Nilai default dan behavior flag |
| `test/firebase_bootstrap_test.dart` | Gate konfigurasi, identitas project, dan initializer Firebase default-off |
| `test/firestore_rules_test.dart` | Konfigurasi rules dan baseline Firestore default-deny |
| `test/release_signing_config_test.dart` | Gate fail-closed dan proteksi material signing Android |
| `test/release_signing_verifier_test.dart` | Verifikasi signature APK dan kecocokan fingerprint signer eksternal |
| `test/adaptive_shell_test.dart` | Navigation/shell berdasarkan ukuran dan tujuan |
| `test/app_layout_test.dart` | Breakpoint dan helper layout |
| `test/theme_design_system_test.dart` | Token/theme/design system |
| `test/dark_theme_component_contrast_test.dart` | Kontras komponen dark mode |
| `test/logo_assets_test.dart` | Asset logo generated |
| `test/receipt_logo_test.dart` | Logo dan format struk |

## Test selection by change

| Perubahan | Verifikasi minimum |
|---|---|
| Copy/UI lokal | format, analyze, widget test terkait |
| Provider/state | analyze, test provider/business flow terkait |
| Checkout/payment/stock | seluruh `pos_business_rules_test`, test database terkait, full suite |
| Catalog/inventory | catalog integrity + business rules + full suite |
| Schema/migration/reset | build_runner, fresh/upgrade DB tests, reset tests, full suite |
| Theme/layout/shared widget | theme, contrast, layout, adaptive shell, screenshot/manual review |
| Printer/drawer/native bridge | unit formatter, Android build, dan test perangkat nyata |
| Feature flag | default-state dan enabled-state tests dengan dart-define yang sama |
| Asset/logo | generator, logo tests, Android build |

## Last known baseline

Pada 21 Juli 2026, dokumentasi audit mencatat:

- `flutter analyze`: tanpa issue.
- `flutter test`: 75 test lulus dan 4 test kompatibilitas dilewati sesuai feature flag.

Baseline adalah referensi historis, bukan pengganti verifikasi task saat ini. Perbarui bagian ini hanya setelah command benar-benar dijalankan pada repository yang sama.

## Verifikasi inkremental terbaru

Pada 8 Agustus 2026, guard identitas project Firebase Talaga ditambahkan dengan
hasil verifikasi aktual:

- Pemeriksaan statis PowerShell: lulus; `approvedProjectId` identik dengan
  alias default `.firebaserc`, jalur mismatch dan regression test tersedia,
  serta tidak ditemukan literal API key/private key pada bootstrap yang
  diubah.
- `dart format --output=none --set-exit-if-changed
  lib/core/config/firebase_bootstrap.dart test/firebase_bootstrap_test.dart`:
  belum terverifikasi; command menunggu lock toolchain tanpa output lalu
  dihentikan.
- `flutter test test/firebase_bootstrap_test.dart
  --dart-define-from-file=firebase.runtime.json`: belum terverifikasi karena
  command yang sama tertahan sebelum test berjalan; permintaan akses SDK di
  luar sandbox ditolak oleh batas penggunaan sistem.
- `flutter analyze`, full suite, dan build Android: tidak dijalankan pada unit
  ini. Bukti packaging Firebase tetap mengikuti blocker PKIX terakhir sampai
  toolchain/trust chain dapat diverifikasi ulang.

Pada 30 Juli 2026, unit aktivasi project Firebase Talaga dan deployment
Firestore default-deny diverifikasi dengan hasil:

- Format dua file test Firebase: lulus, 0 file berubah pada pemeriksaan ulang.
- `flutter test test/firebase_bootstrap_test.dart
  --dart-define-from-file=firebase.runtime.json`: lulus, 4 test; konfigurasi
  build-time lengkap mengarah ke project Talaga.
- `flutter test test/firestore_rules_test.dart`: lulus, 4 test.
- `flutter analyze`: lulus tanpa issue.
- `flutter test`: lulus, 85 test dan 4 skip feature flag lama.
- Firebase MCP: project `talaga-coffee-pos-20260730` dan app Android
  `com.talagacoffee.pos` terbaca `ACTIVE`.
- Firestore `(default)` dibuat di `asia-southeast2`; deployment target
  `firestore` selesai 100%, dan rules live yang dibaca kembali identik dengan
  baseline deny-all repository.
- `flutter build apk --debug
  --dart-define-from-file=firebase.runtime.json`: gagal sebelum menghasilkan
  APK karena Java/Gradle tidak dapat memvalidasi rantai sertifikat repository
  Maven (`PKIX path building failed`). Validasi TLS tidak dinonaktifkan.

Pada 31 Juli 2026, unit gate release signing fail-closed diverifikasi dengan
hasil:

- Format test signing: lulus, 0 file berubah pada pemeriksaan ulang.
- `flutter test test/release_signing_config_test.dart`: lulus, 3 test.
- `flutter analyze`: lulus tanpa issue.
- `flutter test`: lulus, 88 test dan 4 skip feature flag lama.
- `flutter build apk --release` tanpa konfigurasi signing: gagal sesuai desain
  sebelum packaging, dengan empat nama property yang belum tersedia dan tanpa
  menampilkan nilainya.
- Tidak ada artifact release baru. APK release lama di `build/` bertanggal
  22 Juli 2026 tetap merupakan artifact historis dan bukan bukti production
  signing.

Pada 1 Agustus 2026, unit verifier identitas signer APK release diverifikasi
dengan hasil:

- Format dua test signing: lulus, 0 file berubah pada pemeriksaan ulang.
- Parser PowerShell untuk `tool/verify_release_apk.ps1`: lulus tanpa syntax
  error.
- Targeted signing tests: lulus, 7 test; fixture signer yang cocok diterima dan
  fingerprint berbeda ditolak.
- `flutter analyze`: lulus tanpa issue.
- `flutter test`: lulus, 92 test dan 4 skip feature flag lama.
- APK production nyata belum diverifikasi karena keystore, fingerprint release
  eksternal, dan artifact release resmi belum tersedia.

## Manual/device verification gaps

Suite otomatis belum membuktikan:

- Pair/connect/print pada matriks printer Bluetooth nyata.
- Pulse cash drawer pada perangkat nyata.
- Permission Android lintas versi OS.
- Save PDF melalui MediaStore/Downloads dan share flow.
- Upgrade database dari APK produksi lama.
- Startup/checkout performance pada perangkat kelas bawah.
- Startup Firebase Core dengan konfigurasi Talaga pada perangkat Android nyata.
- Production signing dan instalasi release final.

Task yang menyentuh area tersebut harus melaporkan keterbatasan bila device/evidence tidak tersedia.

## Evidence format untuk handoff

Laporkan command dan hasilnya, misalnya:

```text
Verification
- dart format --output=none --set-exit-if-changed lib test tool: PASS
- flutter analyze: PASS
- flutter test test/pos_business_rules_test.dart: PASS (n tests)
- flutter test: PASS (n passed, n skipped)
- Device verification: NOT RUN — printer tidak tersedia
```

Jangan menulis `PASS` bila command tidak dijalankan atau output tidak diperiksa.
