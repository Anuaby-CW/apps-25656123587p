# Talaga Coffee POS

Aplikasi POS Flutter khusus ponsel dan tablet Android yang tetap dapat digunakan tanpa internet. Transaksi disimpan secara lokal di SQLite melalui Drift, pengelolaan state memakai Riverpod, sedangkan printer dan laci kas dipisahkan dalam layanan modular.

## Login Bawaan

- Admin: `admin` / `123456`
- Kasir: `kasir` / `123456`

Kata sandi disimpan sebagai hash SHA-256 lokal, bukan sebagai teks biasa.

## Aturan Utama

- Admin masuk ke Dashboard dan dapat mengakses Transaksi, Laporan, Produk, Kategori, Stok, Biji Kopi, Manual Brew, Add-on, Pengguna, Riwayat Aktivitas, dan Pengaturan.
- Menu POS dan Pesanan hanya tersedia untuk kasir.
- Bayar Sekarang membuat pesanan, detail produk, pembayaran, transaksi, perubahan stok, lalu mencoba mencetak struk.
- Bayar Nanti, Nomor Meja, Shortcut Nama Pelanggan, dan Orders Queue dipertahankan di kode tetapi nonaktif pada build standar. Lihat `DEACTIVATED_FEATURES.md` untuk feature flag dan cara reaktivasi.
- Terima Pembayaran membuat pembayaran dan transaksi untuk pesanan belum lunas, menandainya sebagai lunas, lalu mencoba mencetak struk.
- Transaksi dan Laporan hanya menghitung pesanan lunas.
- Harga Manual Brew mengikuti biji kopi dan pilihan Hot/Ice.
- Format struk termal tersedia untuk kertas ESC/POS 58 mm dan 80 mm.
- Uji laci kas mengirimkan pulsa ESC/POS melalui printer yang terhubung.
- Batas minimum stok dapat diatur per produk dari menu Stok dan ditampilkan sebagai peringatan pada Dashboard.
- Laporan PDF diekspor ke folder `Downloads/Talaga Coffee` pada perangkat Android.

## Struktur Folder lib/

Berikut adalah peta arsitektur cepat untuk folder `lib/`:

```text
lib/
├── app.dart
├── main.dart
├── core/                  # Utilitas sistem, otorisasi rute, & integrasi printer
│   ├── auth/              # Enkripsi & keamanan lokal
│   ├── constants/         # Konstanta global aplikasi
│   ├── files/             # Manajemen penyimpanan berkas lokal
│   ├── permissions/       # Manajemen izin Bluetooth/printer Android
│   ├── printer/           # Driver printer termal ESC/POS & cash drawer
│   ├── routing/           # Rute navigasi dinamis berbasis role
│   ├── theme/             # Kompatibilitas tema lama
│   └── utils/             # Helper format tanggal, uang, logger, & ID generator
├── data/                  # Lapisan data (Drift SQLite & Repositori konkret)
│   ├── database/          # Definisi tabel DB, migrasi, & seed data awal
│   │   └── daos/          # Data Access Objects (modul query SQL terpisah)
│   └── repositories/      # Implementasi konkret dari repositori domain
├── domain/                # Logika bisnis murni (Models, Contracts, Usecases)
│   ├── models/            # Model data & enums global
│   ├── repositories/      # Kontrak (interface) repositori
│   └── usecases/          # Logika alur transaksi & kalkulasi harga
├── presentation/          # Lapisan antarmuka pengguna (UI) & State (Riverpod)
│   ├── providers/         # Penyimpan state global (auth, dark mode, navigasi)
│   ├── widgets/           # Komponen UI tingkat presentasi (loading, empty state)
│   └── [fitur_modul]/     # Modul layar (addons, pos, reports, settings, dll.)
├── theme/                 # Source of truth desain sistem, warna, & typography
└── widgets/               # Komponen visual dasar (atoms/common widgets)
    └── common/            # Widget umum (page frame, custom dropdown, badge)
```

### Detail Folder & Contoh File Utama

*   **lib/**
    *   *Tanggung Jawab*: Inisialisasi awal dan kerangka dasar aplikasi.
    *   *Contoh Berkas*: [main.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/main.dart) (inisialisasi & entry point), [app.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/app.dart) (MaterialApp & pemantau session login).
*   **lib/core/**
    *   *Tanggung Jawab*: Layanan sistem penunjang, perutean akses, serta konektivitas perangkat keras printer termal.
    *   *Contoh Berkas*: 
        *   [app_destination.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/routing/app_destination.dart) (mengatur menu navigasi dan filter hak akses role).
        *   [android_bluetooth_printer_service.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/printer/android_bluetooth_printer_service.dart) & [receipt_formatter_80mm.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/printer/receipt_formatter_80mm.dart) (layanan cetak struk termal).
        *   [report_file_saver.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/files/report_file_saver.dart) (menyimpan laporan PDF secara lokal).
*   **lib/data/**
    *   *Tanggung Jawab*: Komunikasi langsung dengan SQLite database menggunakan Drift ORM dan penyediaan data untuk repositori.
    *   *Contoh Berkas*:
        *   [app_database.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/data/database/app_database.dart) & [seed_data.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/data/database/seed_data.dart) (definisi skema DB & data awal default).
        *   [orders_dao.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/data/database/daos/orders_dao.dart) (query pesanan & transaksi).
        *   [catalog_repository.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/data/repositories/catalog_repository.dart) (penghubung data produk ke lapisan domain).
*   **lib/domain/**
    *   *Tanggung Jawab*: Logika bisnis murni (enterprise logic) yang independen dari platform dan library database/UI.
    *   *Contoh Berkas*:
        *   [enums.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/domain/models/enums.dart) (definisi status order, payment, dan peran user).
        *   [checkout_usecase.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/domain/usecases/checkout_usecase.dart) (alur validasi pembayaran & pengurangan stok).
        *   [manual_brew_pricing.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/domain/usecases/manual_brew_pricing.dart) (kalkulator harga kopi manual brew).
*   **lib/presentation/**
    *   *Tanggung Jawab*: Lapisan interaksi UI pengguna serta manajemen state (Riverpod).
    *   *Contoh Berkas*:
        *   [app_providers.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/providers/app_providers.dart) (state global untuk sesi login, mode gelap, & halaman terpilih).
        *   [dashboard_shell.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/dashboard/dashboard_shell.dart) (kerangka visual pembagi layar admin vs kasir).
        *   [pos_screen.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/pos/pos_screen.dart) (layar utama POS kasir).
        *   [reports_screen.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/reports/reports_screen.dart) (layar dashboard laporan admin).
*   **lib/theme/**
    *   *Tanggung Jawab*: Penyedia sentral desain sistem (Source of Truth) seperti warna kustom, tata letak, margin, typografi, dan transisi.
    *   *Contoh Berkas*: [app_theme.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/theme/app_theme.dart) (logika pembentuk tema admin/kasir), [app_colors.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/theme/app_colors.dart) (palet warna kustom).
*   **lib/widgets/**
    *   *Tanggung Jawab*: Atom/Komponen UI umum dasar yang dapat digunakan ulang di layar mana pun.
    *   *Contoh Berkas*: [app_page_frame.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/widgets/common/app_page_frame.dart) (kerangka standar halaman POS/Admin), [app_status_badge.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/widgets/common/app_status_badge.dart) (badge label status).

---

## Dual-Role System

Aplikasi ini menggunakan pemisahan akses peran (**Admin** vs **Kasir**) untuk membedakan fitur manajemen outlet dan fitur kasir transaksi.

*   **Definisi Role**: Ditentukan lewat enum `UserRole` di [enums.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/domain/models/enums.dart).
*   **Filter Akses Menu**: Diatur secara terpusat di berkas [app_destination.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/routing/app_destination.dart) menggunakan bendera `adminOnly` dan fungsi `isAllowed()`. Menu POS & Pesanan khusus untuk kasir, sedangkan Laporan, Stok, Add-on, Pengguna, dan Audit Trail khusus untuk admin.
*   **Perbedaan Tampilan & Workspace**: Logikanya berada di [dashboard_shell.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/dashboard/dashboard_shell.dart). Dashboard membagi layout menjadi `_AdminWorkspaceShell` (tema biru-teal) dan `_CashierWorkspaceShell` (tema cokelat-wood) berdasarkan peran pengguna yang terotentikasi.

---

## Theme System

Pewarnaan dan gaya visual aplikasi diatur secara terpusat (dinamis berdasarkan peran pengguna) untuk menjaga konsistensi UI.

*   **Source of Truth (Pusat Gaya)**: Berada di dalam folder [lib/theme/](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/theme/), utamanya pada berkas [app_theme.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/theme/app_theme.dart) (berisi skema ThemeData Material 3) dan [app_colors.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/theme/app_colors.dart) (palette warna).
*   **Jalur Kompatibilitas**: Berkas [lib/core/theme/app_theme.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/core/theme/app_theme.dart) hanya mengekspor source of truth asli untuk backward compatibility.
*   **Konsumen Tema**:
    *   [app.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/app.dart) mengonsumsi tema awal (`AppTheme.guest`) pada tingkat root MaterialApp.
    *   [dashboard_shell.dart](file:///c:/Users/Administrator/Videos/New folder/talaga_coffee_pos/lib/presentation/dashboard/dashboard_shell.dart) mengonsumsi `AppTheme.admin` atau `AppTheme.cashier` secara dinamis tergantung status login dan menginjeksinya melalui widget `Theme(...)`.
    *   Seluruh screens/widgets di lapisan presentasi mengonsumsi warna/style lewat `Theme.of(context)` atau mengimpor token spacing (`AppSpacing`), radius (`AppRadius`), dan warna kustom secara langsung.

## Build APK Android

```bash
flutter pub get
dart run build_runner build
flutter test
flutter analyze
flutter build apk --release
```

Lokasi APK release:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build release saat ini masih memakai konfigurasi signing debug untuk pengujian internal. Ganti dengan signing Android resmi sebelum distribusi produksi atau publikasi ke Play Store.
