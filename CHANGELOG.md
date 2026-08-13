# Changelog

## 2026-08-08 - Guard identitas project Firebase Talaga

### Unit pekerjaan

Menambahkan satu guard fail-closed agar bootstrap Firebase hanya menerima
`FIREBASE_PROJECT_ID` milik project Talaga yang sudah disetujui di
`.firebaserc`. Acceptance unit ini adalah konfigurasi kosong tetap default-off,
konfigurasi parsial tetap ditolak, project berbeda ditolak sebelum initializer,
dan project Talaga tetap diteruskan. Regression test sudah ditambahkan, tetapi
eksekusi Dart/Flutter belum dapat diselesaikan karena akses toolchain pada run
ini tertahan.

### File dan area berubah

- Bootstrap Firebase: `lib/core/config/firebase_bootstrap.dart`.
- Regression test: `test/firebase_bootstrap_test.dart`.
- Source of truth: `docs/product/REQUIREMENTS.md`,
  `docs/engineering/ARCHITECTURE.md`, dan `docs/quality/TESTING.md`.
- Dokumentasi eksekusi: `CHANGELOG.md`.

### Perilaku

- Konfigurasi lengkap dengan project ID selain
  `talaga-coffee-pos-20260730` sekarang melempar
  `FirebaseProjectMismatchException` sebelum `Firebase.initializeApp`.
- Pesan error tidak memuat project ID yang ditolak atau nilai konfigurasi
  lainnya.
- Build tanpa konfigurasi Firebase tetap default-off dan Drift/SQLite tetap
  menjadi satu-satunya sumber data operasional.
- Firestore tetap default-deny; Auth, cloud mirror/sync, App Check, backend
  QRIS, role staff, dan pembatasan Admin read-only tidak diaktifkan.

### Verifikasi aktual

- Pemeriksaan konsistensi statis PowerShell: PASS; konstanta project bootstrap
  identik dengan alias default `.firebaserc`.
- Pemeriksaan jalur guard/test: PASS; exception mismatch, regression test, dan
  assertion bahwa initializer tidak dipanggil tersedia.
- Scan literal API key/private key pada bootstrap yang diubah: PASS; tidak ada
  material tersebut yang terdeteksi.
- `dart format --output=none --set-exit-if-changed
  lib/core/config/firebase_bootstrap.dart test/firebase_bootstrap_test.dart`:
  NOT RUN sampai selesai; command menunggu lock toolchain tanpa output lalu
  dihentikan.
- `flutter test test/firebase_bootstrap_test.dart
  --dart-define-from-file=firebase.runtime.json`: NOT RUN sampai test; proses
  tertahan sebelum mengeluarkan output. Permintaan akses SDK di luar sandbox
  ditolak karena batas penggunaan sistem.
- `flutter analyze`, full suite, dan build APK Android: NOT RUN pada unit ini.
  Tidak ada artifact build baru.

### Keamanan dan asumsi

- Project ID Firebase bukan credential dan sudah menjadi konfigurasi repository
  pada `.firebaserc`; API key, app ID, sender ID, dan nilai runtime lokal tidak
  ditambahkan atau dicetak.
- Guard ini hanya membatasi identitas project saat bootstrap; ia bukan bukti
  bahwa Firebase Core sudah terpaket atau berjalan pada perangkat Android.
- Tidak ada trust store, TLS, dependency, keystore, credential, generated file,
  atau konfigurasi global yang diubah.

### Risiko dan blocker

- Format, targeted test, analysis, dan full suite masih harus dijalankan sebelum
  unit ini dianggap tervalidasi dinamis.
- Gate packaging Firebase tetap belum lulus berdasarkan bukti terakhir:
  Gradle/JBR gagal memvalidasi rantai CA repository dengan PKIX. Production
  signing nyata, hardening autentikasi, role staff, Admin read-only, dan QRIS
  tetap tidak boleh dilanjutkan.
- Production signing masih menunggu keystore resmi, empat nilai eksternal,
  fingerprint signer privat, artifact resmi, dan install/update test.

### Langkah berikutnya

Setelah akses toolchain tersedia, jalankan formatter dua file, targeted test
Firebase dengan konfigurasi runtime lokal, `flutter analyze`, dan full suite.
Hanya setelah rantai CA resmi diperbaiki, ulangi build APK debug Firebase dan
startup test perangkat. Jangan lanjut ke gate downstream sebelum bukti tersebut
lulus.

## 2026-08-07 - Verifikasi ulang packaging Android Firebase

### Unit pekerjaan

Memverifikasi ulang gate packaging Firebase Core pada toolchain saat ini dengan
konfigurasi runtime lokal Talaga. Acceptance unit ini adalah test bootstrap
lulus dan build menghasilkan APK debug baru tanpa bypass TLS. Test bootstrap
lulus, tetapi packaging masih berhenti pada trust chain; karena itu tidak ada
perubahan source/runtime dan tidak ada pekerjaan downstream yang dimulai.

### File dan area berubah

- Dokumentasi eksekusi: `CHANGELOG.md`.
- Tidak ada source, test, dependency, konfigurasi global, trust store,
  credential, generated file, atau artifact build yang diubah secara sengaja.

### Perilaku

- Firebase tetap opt-in melalui `firebase.runtime.json` yang diabaikan Git.
- Drift/SQLite tetap menjadi satu-satunya sumber data operasional offline-first.
- Firestore tetap default-deny; Auth, cloud mirror/sync, App Check, backend
  QRIS, role staff, dan pembatasan Admin read-only tidak diaktifkan.
- Production signing tetap fail-closed dan tidak diuji sebagai artifact nyata
  karena gate Firebase sebelumnya belum lulus dan material signing eksternal
  belum tersedia.

### Verifikasi aktual

- Pemeriksaan konfigurasi runtime lokal: PASS; file tersedia dan empat field
  wajib terisi. Nilai konfigurasi tidak dicetak.
- `flutter test test/firebase_bootstrap_test.dart
  --dart-define-from-file=firebase.runtime.json`: PASS, 4 test.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 92 test dan 4 skip feature flag lama.
- `flutter build apk --debug
  --dart-define-from-file=firebase.runtime.json`: FAIL pada
  `:app:mergeDebugAssets`. Firebase BoM 34.15.0 tidak dapat diunduh dari Google
  Maven, Maven Central, maupun Flutter storage karena `certificate_unknown`
  dan `PKIX path building failed`; retry otomatis Flutter gagal sama.
- Output APK hanya berisi `app-release.apk` historis bertanggal 22 Juli 2026.
  Tidak ada `app-debug.apk` atau artifact baru yang dihasilkan.
- Startup/device test: NOT RUN karena APK Firebase tidak berhasil dibangun dan
  perangkat Android tidak tersedia pada run ini.

### Keamanan dan asumsi

- TLS tidak dinonaktifkan, CA tidak ditebak/diimpor, dan trust store serta
  konfigurasi Flutter/Gradle global tidak diubah.
- Tidak ada keystore, password, credential, secret, atau fingerprint produksi
  yang ditambahkan atau dicetak.
- Error seragam pada tiga repository resmi menunjukkan JBR/Gradle masih tidak
  memiliki rantai CA yang diperlukan pada jaringan/mesin ini; perbaikannya
  memerlukan sumber CA resmi atau JDK 21 terkelola dari pemilik mesin.

### Risiko dan blocker

- Firebase foundation belum lulus packaging Android, sehingga release signing
  nyata, hardening autentikasi, role staff, Admin read-only, dan QRIS tidak
  boleh dilanjutkan pada urutan automation ini.
- Production signing tetap menunggu keystore resmi, empat nilai signing
  eksternal, fingerprint signer privat, APK resmi, dan install/update test.
- Peringatan migrasi Built-in Kotlin dari `print_bluetooth_thermal` masih
  muncul, tetapi bukan penyebab kegagalan build ini dan tidak diubah.

### Langkah berikutnya

Pemilik mesin/jaringan memasang rantai CA resmi ke JBR yang dipakai
Flutter/Gradle atau menyediakan JDK 21 terkelola yang dapat memvalidasi
repository resmi. Setelah itu ulangi build APK debug Firebase dan verifikasi
startup pada perangkat Android. Jangan lanjut ke Auth, signing nyata, role,
Admin read-only, atau QRIS sebelum gate terkait memiliki bukti verifikasi.

## 2026-08-02 - Verifikasi trust chain Android untuk Firebase

### Unit pekerjaan

Memverifikasi ulang gate build Android Firebase Core memakai konfigurasi runtime
Talaga yang disimpan lokal. Unit ini hanya menguji integrasi Android dan
menegaskan blocker trust chain; tidak mengubah kode aplikasi, dependency,
konfigurasi global, trust store, atau perilaku runtime.

### File dan area berubah

- Dokumentasi eksekusi: `CHANGELOG.md`.
- Tidak ada source, test, generated file, credential, maupun artifact build
  yang diubah atau ditambahkan secara sengaja.

### Perilaku

- Firebase tetap opt-in melalui `firebase.runtime.json` yang diabaikan Git.
- Drift/SQLite tetap menjadi satu-satunya sumber data operasional offline-first.
- Firestore tetap default-deny; Auth, cloud mirror/sync, App Check, backend
  QRIS, role staff, dan pembatasan Admin read-only tidak diaktifkan.
- Production signing tetap fail-closed dan belum dianggap berjalan.

### Verifikasi aktual

- `flutter test test/firebase_bootstrap_test.dart
  --dart-define-from-file=firebase.runtime.json`: PASS, 4 test.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 92 test dan 4 skip feature flag lama.
- `flutter build apk --debug
  --dart-define-from-file=firebase.runtime.json`: FAIL pada
  `:app:mergeDebugAssets`; JBR/Gradle gagal mengunduh Firebase BoM 34.15.0 dari
  Google Maven, Maven Central, dan Flutter storage karena
  `PKIX path building failed`. Tidak ada APK debug baru.
- Percobaan process-local dengan
  `-Djavax.net.ssl.trustStoreType=Windows-ROOT`: FAIL aman; JBR 21.0.10 milik
  Android Studio melaporkan `Windows-ROOT not found`. Opsi hanya berlaku pada
  proses tersebut dan tidak disimpan.
- `flutter doctor -v`: Android toolchain dan network resources terdeteksi,
  tetapi bukti ini tidak menggantikan build Gradle yang gagal.
- Artifact `app-release.apk` yang tersisa bertanggal 22 Juli 2026 dan tetap
  bukan bukti production signing; `app-debug.apk` tidak ada setelah percobaan.

### Keamanan dan asumsi

- Validasi TLS tidak dinonaktifkan, sertifikat tidak diimpor, dan trust store
  Java/Windows tidak diubah.
- Tidak ada keystore, password, credential, secret, atau fingerprint produksi
  yang ditambahkan atau dicetak.
- Perbaikan trust chain memerlukan CA resmi yang sesuai dengan jaringan ini
  atau JDK/toolchain yang sudah memiliki rantai kepercayaan sah; CA tidak boleh
  diekspor atau dipilih dengan menebak.

### Risiko dan blocker

- Firebase Core belum terbukti dapat dipaketkan ke APK Android pada mesin ini,
  sehingga gate Firebase foundation belum lengkap.
- Penyebab trust chain harus diselesaikan oleh pemilik mesin/jaringan melalui
  mekanisme CA resmi. Bypass TLS, trust-all, dan perubahan trust store tanpa
  sumber sertifikat terverifikasi tidak boleh digunakan.
- Production signing masih menunggu keystore resmi, empat nilai signing
  eksternal, fingerprint signer privat, build APK resmi, dan device test.
- Peringatan migrasi Built-in Kotlin dari plugin
  `print_bluetooth_thermal` muncul saat build, tetapi bukan penyebab kegagalan
  saat ini dan tidak diubah dalam unit ini.

### Langkah berikutnya

Pemilik mesin/jaringan menyediakan atau memasang rantai CA resmi ke JBR yang
dipakai Flutter/Gradle, atau menyediakan JDK 21 terkelola yang dapat
memvalidasi ketiga repository resmi. Setelah itu ulangi build APK debug Firebase
dan verifikasi startup pada perangkat Android. Jangan lanjut ke Auth, role
staff, Admin read-only, atau QRIS sebelum gate Firebase dan production signing
benar-benar lulus.

## 2026-08-01 - Verifier identitas signer APK release

### Unit pekerjaan

Menambahkan gate verifikasi artifact APK release yang memastikan signature
valid dan fingerprint SHA-256 signer cocok dengan fingerprint produksi yang
diberikan secara eksternal. Unit ini tidak membuat keystore, tidak menyimpan
fingerprint aktual, dan tidak menghasilkan artifact produksi.

### File dan area berubah

- Tooling release: `tool/verify_release_apk.ps1`.
- Test: `test/release_signing_verifier_test.dart` dan
  `test/release_signing_config_test.dart`.
- Source of truth: `docs/engineering/RELEASE_SIGNING.md`,
  `docs/product/REQUIREMENTS.md`, `docs/engineering/ARCHITECTURE.md`, dan
  `docs/quality/TESTING.md`.

### Perilaku

- Verifier hanya menerima file `.apk` yang ada dan fingerprint SHA-256
  eksternal sepanjang 64 karakter hex.
- `apksigner verify --verbose --print-certs --Werr` wajib sukses.
- APK dengan signer ambigu atau fingerprint berbeda ditolak.
- Output sukses tidak mencetak fingerprint; password dan material signing tidak
  dibaca oleh verifier.
- Dokumentasi tidak lagi menyarankan `apksigner` untuk AAB karena tool tersebut
  khusus APK; jalur AAB tetap memerlukan tooling resmi terpisah.
- Runtime POS, Drift, Firebase, Firestore rules, Auth, sync, App Check, QRIS,
  feature flag, dan role tidak berubah.

### Verifikasi aktual

- Formatter Dart untuk dua test signing: PASS, 0 perubahan pada pemeriksaan
  ulang.
- Parser PowerShell untuk verifier: PASS, tanpa syntax error.
- Targeted signing tests: PASS, 7 test; fixture fingerprint cocok diterima dan
  fingerprint berbeda ditolak.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 92 test dan 4 skip feature flag lama.
- Percobaan awal `flutter build apk --debug
  --dart-define-from-file=firebase.runtime.json`: INCONCLUSIVE, timeout 240
  detik tanpa output dan tanpa APK debug baru. Diagnosis berikutnya menunjukkan
  Flutter membutuhkan akses ke lockfile SDK di luar sandbox; analyze/test
  berhasil setelah akses tersebut diberikan. Error PKIX tidak muncul dan juga
  belum dapat dinyatakan selesai pada run ini.
- APK release nyata tidak diverifikasi karena keystore, fingerprint produksi,
  dan artifact resmi belum tersedia.

### Keamanan dan asumsi

- Tidak ada keystore, password, alias privat, credential, secret, atau
  fingerprint produksi yang ditambahkan ke repository.
- Fingerprint yang dipakai test adalah fixture sintetis, bukan identitas
  sertifikat nyata.
- Fingerprint produksi dan lokasi backup tetap dimiliki release record privat.

### Risiko dan blocker

- Production signing belum berjalan: keystore resmi dan empat nilai signing
  eksternal belum tersedia.
- Kecocokan signer pada APK nyata, instalasi baru, update dari versi lama, dan
  device test belum dapat dibuktikan.
- Trust chain Java/Gradle untuk dependency Firebase belum teruji ulang sampai
  build Android selesai; jangan menganggap PKIX sudah pulih.
- Jalur AAB/Play App Signing masih memerlukan verifikasi resmi terpisah.
- Metadata Git tetap tidak dapat dipakai: `git status` melaporkan repository
  tidak valid karena `.git/HEAD` tidak tersedia.

### Langkah berikutnya

Pemilik release menyediakan keystore, empat nilai signing, dan fingerprint
SHA-256 sertifikat melalui storage privat. Setelah itu build APK release,
jalankan verifier repository terhadap artifact tersebut, lalu uji instalasi
baru/update pada perangkat Android. Secara terpisah, ulangi build debug dengan
runtime Firebase untuk membuktikan trust chain dan startup Android. Jangan
lanjut ke hardening autentikasi sebelum production signing terbukti.

## 2026-07-31 - Release signing Android fail-closed

### Unit pekerjaan

Menghapus fallback debug signing dari build release Android dan menambahkan
gate konfigurasi production signing yang hanya menerima empat Gradle
property/environment variable eksternal secara lengkap. Unit ini tidak membuat
keystore, tidak mengisi credential, dan tidak menghasilkan artifact produksi.

### File dan area berubah

- Build Android: `android/app/build.gradle.kts`.
- Proteksi material lokal: `.gitignore`.
- Test: `test/release_signing_config_test.dart`.
- Checklist: `docs/engineering/RELEASE_SIGNING.md`.
- Source of truth: `PRD.md`, `docs/product/REQUIREMENTS.md`,
  `docs/engineering/ARCHITECTURE.md`, dan `docs/quality/TESTING.md`.

### Perilaku

- Task release tidak lagi memakai `signingConfigs.debug`.
- Build release berhenti jika salah satu `TALAGA_RELEASE_*` kosong.
- Path keystore harus absolut, berada di luar repository, dan menunjuk file
  yang ada ketika task release dijalankan.
- Nilai dapat berasal dari Gradle property user atau environment variable;
  pesan gagal hanya menampilkan nama property yang belum tersedia.
- Build debug, Firebase default-off, Firestore deny-all, dan alur Drift
  offline-first tidak berubah.

### Verifikasi aktual

- Format `test/release_signing_config_test.dart`: PASS, 0 perubahan pada
  pemeriksaan ulang.
- `flutter test test/release_signing_config_test.dart`: PASS, 3 test.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 88 test dan 4 skip feature flag lama.
- `flutter build apk --release` tanpa konfigurasi signing: BLOCKED sesuai
  desain sebelum packaging; error mencantumkan empat nama property yang hilang
  tanpa nilai rahasia.
- Tidak ada artifact release baru. APK release historis dalam `build/`
  bertanggal 22 Juli 2026 tidak diperbarui dan bukan bukti production signing.

### Keamanan dan asumsi

- Tidak ada keystore, password, alias privat, credential, atau secret yang
  ditambahkan.
- Keystore production akan dibuat/disediakan oleh pemilik release, disimpan dan
  dicadangkan di luar repository melalui media rahasia yang disetujui.
- Build release yang sengaja gagal tanpa credential adalah bukti gate
  fail-closed, bukan bukti bahwa production signing sudah berjalan.

### Risiko dan blocker

- Keystore resmi dan empat nilai signing belum tersedia, sehingga signature
  artifact dan instalasi/update perangkat belum dapat diverifikasi.
- Trust chain Java/Gradle yang sebelumnya mengalami `PKIX path building failed`
  belum teruji ulang karena gate signing menghentikan build lebih awal.
- APK release lama di folder generated `build/` tidak boleh didistribusikan.
- Firebase Auth, cloud mirror/sync, App Check, dan QRIS tetap belum aktif.

### Langkah berikutnya

Pemilik release perlu menyediakan keystore resmi dan nilai signing melalui
storage eksternal yang aman. Setelah itu jalankan build release, perbaiki trust
chain secara aman bila error PKIX muncul kembali, verifikasi sertifikat dengan
`apksigner`, lalu uji instalasi/update pada perangkat Android. Jangan lanjut ke
hardening autentikasi sampai production signing benar-benar terbukti.

## 2026-07-30 - Project Firebase Talaga aktif dan Firestore tetap tertutup

### Unit pekerjaan

Membuat project Firebase khusus Talaga, mendaftarkan aplikasi Android,
menyediakan konfigurasi runtime lokal untuk bootstrap, serta membuat dan
men-deploy database Firestore dengan rules default-deny.

### Resource Firebase

- Project ID: `talaga-coffee-pos-20260730`.
- Project number: `387060441536`.
- App Android: `Talaga Coffee POS Android`.
- Package Android: `com.talagacoffee.pos`.
- Firestore database: `(default)`.
- Region: `asia-southeast2` (Jakarta).

### File dan area berubah

- Project mapping: `.firebaserc`.
- Konfigurasi Firebase CLI: `firebase.json`, `firestore.indexes.json`.
- Runtime lokal: `firebase.runtime.json` (diabaikan Git).
- Template aman: `firebase.runtime.example.json`, `.gitignore`.
- Test: `test/firebase_bootstrap_test.dart`,
  `test/firestore_rules_test.dart`.
- Source of truth: `docs/product/REQUIREMENTS.md`,
  `docs/engineering/ARCHITECTURE.md`, dan `docs/quality/TESTING.md`.

### Perilaku

- Build yang memakai
  `--dart-define-from-file=firebase.runtime.json` menginisialisasi Firebase Core
  ke project Talaga yang terdaftar.
- Build tanpa runtime config tetap berjalan offline-first dengan Firebase
  nonaktif.
- Drift/SQLite tetap menjadi satu-satunya sumber data operasional.
- Database Firestore cloud tersedia, tetapi seluruh read/write tetap ditolak
  oleh rules live default-deny.
- Firebase Auth, cloud mirror/sync, App Check, dan backend QRIS belum aktif.

### Verifikasi aktual

- Format dua file test Firebase: PASS, 0 perubahan pada pemeriksaan ulang.
- Bootstrap test dengan runtime config Talaga: PASS, 4 test.
- Firestore config/rules test: PASS, 4 test.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 85 test dan 4 skip feature flag lama.
- Firebase project dan app Android: `ACTIVE`.
- Deploy Firestore: PASS, job selesai 100%.
- Readback rules live: PASS, identik dengan deny-all repository.
- `flutter build apk --debug` dengan runtime config: FAIL sebelum menghasilkan
  APK karena trust chain Java/Gradle (`PKIX path building failed`).

### Keamanan dan asumsi

- Nilai runtime project-specific hanya disimpan di
  `firebase.runtime.json` yang diabaikan Git; nilai tersebut tidak disalin ke
  source, test, dokumentasi, atau changelog.
- `.firebaserc` hanya menyimpan project ID dan tidak berisi token login.
- Region Jakarta dipilih untuk mendekatkan backend ke operasional Indonesia;
  lokasi Firestore tidak dapat diubah setelah database dibuat.
- Rules tidak dibuka sebelum Auth, App Check, model akses, dan scope sinkronisasi
  disetujui serta diuji.

### Risiko dan langkah berikutnya

- APK Android belum terverifikasi sampai trust store Java/Gradle diperbaiki
  tanpa menonaktifkan TLS.
- Startup Firebase pada perangkat nyata belum dijalankan.
- Release signing masih memakai debug signing dan belum layak produksi.
- Unit aman berikutnya adalah memperbaiki trust chain build, memverifikasi APK
  pada perangkat, lalu mengerjakan release signing. Auth/sync tetap menunggu
  urutan dan scope yang disetujui.

## 2026-07-30 — Firestore Security Rules default-deny

### Unit pekerjaan

Menambahkan baseline konfigurasi Firestore yang menolak seluruh read/write.
Unit ini hanya menyiapkan boundary keamanan repository; tidak mengaktifkan
Firestore, Auth, cloud mirror/sync, App Check, atau backend QRIS.

### File dan area berubah

- Konfigurasi Firebase lokal-repository: `firebase.json`.
- Security Rules: `firestore.rules`.
- Test regresi: `test/firestore_rules_test.dart`.
- Source of truth: `docs/product/REQUIREMENTS.md`,
  `docs/engineering/ARCHITECTURE.md`, dan `docs/quality/TESTING.md`.

### Perilaku

- `firebase.json` hanya menunjuk ke `firestore.rules` dan tidak menyimpan
  project ID atau credential.
- Seluruh document read/write ditolak oleh baseline rules.
- Drift/SQLite tetap menjadi satu-satunya sumber data operasional.
- Rules belum dideploy; tidak ada akses cloud yang menjadi aktif.

### Verifikasi aktual

- Format `test/firestore_rules_test.dart`: PASS, 0 file perlu diubah setelah
  formatting.
- `flutter test test/firestore_rules_test.dart`: PASS, 2 test.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test`: PASS, 82 test dan 4 skip feature flag lama.
- Pencarian pola project config, credential, dan rules permisif pada unit:
  tidak menemukan nilai project-specific, secret, atau `allow ... if true`.
- `firebase --version`: BLOCKED; Firebase CLI tidak terpasang.
- Percobaan `assembleRelease`: INCOMPLETE. Gradle 9.1.0 berhasil diunduh dari
  sumber resmi setelah izin network, tetapi build tidak selesai dalam batas
  waktu dan tidak menghasilkan APK. Proses Gradle orphan dari percobaan ini
  dihentikan.

### Asumsi

- Rules default-deny adalah baseline sementara sampai model Auth, App Check,
  ownership/outlet scope, dan conflict handling disetujui.
- Deploy rules selalu dilakukan terhadap project Firebase Talaga yang
  disetujui melalui tooling/otoritas eksternal, bukan dari project ID yang
  di-commit.

### Risiko dan blocker

- Syntax/semantics rules belum diuji melalui Firebase Emulator karena CLI tidak
  tersedia.
- Rules belum dideploy dan database Firebase nyata belum terhubung atau
  terverifikasi.
- Konfigurasi project/credential dan perangkat Android tidak tersedia.
- Release signing masih memakai debug signing dan belum layak produksi.
- Metadata `.git` tetap tidak lengkap, sehingga status/diff Git tidak dapat
  dipakai sebagai bukti perubahan.

### Langkah berikutnya

Pasang/otorisasi Firebase CLI atau gunakan pipeline resmi, jalankan test rules
di emulator, lalu deploy baseline deny-all ke project Talaga yang disetujui dan
verifikasi penolakan read/write. Jangan menambah allow-rule sebelum Auth,
App Check, model akses, serta scope mirror/sync disetujui.

## 2026-07-29 — Firebase Core bootstrap default-off

### Unit pekerjaan

Menambahkan boundary bootstrap Firebase paling awal tanpa mengubah Drift/SQLite
sebagai sumber data operasional offline-first. Firebase tetap nonaktif pada build
standar tanpa konfigurasi eksternal.

### File dan area berubah

- Startup dan konfigurasi: `lib/main.dart`,
  `lib/core/config/firebase_bootstrap.dart`.
- Dependency: `pubspec.yaml`, `pubspec.lock` (`firebase_core 4.12.1`).
- Test: `test/firebase_bootstrap_test.dart`.
- Proteksi konfigurasi lokal: `.gitignore`.
- Source of truth: `docs/product/REQUIREMENTS.md`,
  `docs/engineering/ARCHITECTURE.md`, `docs/quality/TESTING.md`.
- Artifact plugin lokal `.flutter-plugins-dependencies` diperbarui otomatis oleh
  `flutter pub get`; tidak diedit manual.

### Perilaku

- Tanpa seluruh `FIREBASE_*` dart-define, Firebase tetap nonaktif bila semua
  nilai kosong.
- Konfigurasi parsial ditolak sebelum initializer dipanggil.
- Konfigurasi lengkap diteruskan sebagai `FirebaseOptions`.
- File `firebase.runtime*.json` di root diabaikan Git untuk mencegah konfigurasi
  project-specific ikut ter-commit.
- Tidak ada Firebase Auth, cloud mirror/sync, Security Rules, App Check, atau
  backend QRIS yang diaktifkan.

### Verifikasi aktual

- `flutter pub get`: PASS; tiga dependency Firebase ter-resolve.
- `dart format --output=none --set-exit-if-changed` untuk tiga file Dart yang
  disentuh: PASS, 0 file berubah.
- `flutter analyze`: PASS, tanpa issue.
- `flutter test test/firebase_bootstrap_test.dart`: PASS, 3 test.
- `flutter test`: PASS, 80 test dan 4 skip feature flag lama.
- Pencarian pola API key/private key/password signing pada source non-generated:
  tidak menemukan credential baru.
- `flutter build apk --release`: BLOCKED. Gradle gagal mengunduh Firebase BoM
  karena validasi sertifikat Java (`PKIX path building failed`) pada Google
  Maven/Maven Central/Flutter storage. Tidak ada APK release terverifikasi.
- Pemeriksaan format seluruh `lib test tool`: FAIL pada lima file lama di luar
  unit ini. Command memakai `--output=none`; file lama tersebut tidak diubah.

### Asumsi

- Nilai Firebase project diberikan hanya melalui file lokal yang tidak
  di-commit dan `--dart-define-from-file`.
- Firebase tidak diperlukan untuk alur aktif hingga Auth/sync ditambahkan dalam
  unit terpisah; startup default tetap offline-first.

### Risiko dan blocker

- Integrasi native Android Firebase Core belum terbukti melalui APK karena trust
  store Java/Gradle pada mesin ini menolak rantai sertifikat repository Maven.
- Inisialisasi dengan project Firebase nyata dan perangkat Android belum diuji
  karena konfigurasi project/credential/perangkat tidak tersedia.
- Build release masih memakai debug signing; hasil build apa pun belum boleh
  dianggap paket produksi.
- Metadata `.git` tidak lengkap (`.git/HEAD` tidak ada), sehingga status/diff Git
  tidak tersedia untuk memisahkan perubahan lama dari unit ini.

### Langkah berikutnya

Pulihkan trust chain Java/Gradle secara aman, unduh artifact Firebase dari
repository resmi, lalu ulangi build Android. Setelah itu, gunakan project
Firebase yang disetujui untuk memverifikasi startup nyata sebelum menambah cloud
mirror/sync, Security Rules, dan App Check sebagai unit-unit terpisah.
