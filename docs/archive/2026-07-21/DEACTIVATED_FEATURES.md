# Fitur Dinonaktifkan dan Panduan Reaktivasi

Dokumen ini menjadi sumber operasional untuk fitur yang **dipertahankan di
repository tetapi dinonaktifkan pada build standar**, terakhir diperbarui
20 Juli 2026.
Implementasi, skema, dan data lama tidak dihapus.

PRD utama hanya mendokumentasikan kapabilitas build standar. Detail fitur yang
diparkir dan artefak kompatibilitas lama dipusatkan di dokumen ini agar status
fitur aktif tidak tercampur dengan kode yang tidak lagi memiliki alur pengguna.

## Status dan feature flag

| Fitur | Status default | Feature flag | Dampak saat nonaktif |
|---|---|---|---|
| Shortcut Nama Pelanggan (`Pelanggan Umum`) | Nonaktif | `FEATURE_CUSTOMER_NAME_SHORTCUT` | Shortcut disembunyikan; nama pelanggan tetap wajib diketik. |
| Nomor Meja | Nonaktif | `FEATURE_TABLE_NUMBER` | Input/chip meja disembunyikan, checkout Dine In tidak mewajibkan nomor meja, dan order baru menyimpan `tableNumber = null`. |
| Bayar Nanti | Nonaktif | `FEATURE_PAY_LATER` | Tombol disembunyikan dan request `payNow: false` ditolak oleh use case. |
| Antrean Pesanan (Orders Queue) | Nonaktif | `FEATURE_ORDERS_QUEUE` | Tujuan/menu Pesanan tidak tersedia untuk Admin maupun Kasir. Screen, provider, repository, dan data order lama tetap ada. |
| Akses POS Admin | Nonaktif | `FEATURE_ADMIN_POS_ACCESS` | Tujuan POS tidak tersedia bagi Admin; POS tetap aktif bagi Kasir. |
| Metrik Pesanan Dibatalkan di Laporan | Nonaktif | `FEATURE_CANCELLED_ORDERS_REPORT` | Kartu laporan dan baris ekspor PDF disembunyikan. |
| Kontrol Pengelolaan Stok di Pengaturan | Nonaktif | `FEATURE_INVENTORY_MANAGEMENT_SETTING` | Panel switch disembunyikan dari Pengaturan Admin; halaman Stok tetap aktif. |

## Artefak kompatibilitas tanpa UI aktif

Artefak berikut masih ada untuk menjaga kompatibilitas database dan kode lama,
tetapi bukan requirement aktif build standar:

- `ProductFavorites` beserta provider/repository/test-nya; tidak ada kontrol
  favorit pada POS.
- `ManualBrewMethods` beserta seed/DAO/repository dan snapshot order lama;
  Manual Brew aktif hanya memakai biji kopi serta pilihan Panas/Dingin.
- `CafeTables`; checkout aktif tidak membaca master meja ini.
- Alur order belum lunas, penerimaan pembayaran tertunda, pembatalan, dan
  perubahan status pada layar Pesanan; seluruh UI-nya bergantung pada flag
  Bayar Nanti dan Orders Queue.

Artefak tersebut tidak boleh dianggap aktif hanya karena tabel, provider,
repository, atau test kompatibilitasnya masih tersedia.

Semua flag didefinisikan di
`lib/core/config/feature_flags.dart` menggunakan `bool.fromEnvironment`.
Perubahan flag membutuhkan build ulang aplikasi.

## Cara mengaktifkan kembali

Aktifkan semua fitur yang diparkir saat menjalankan aplikasi:

```powershell
flutter run --dart-define=FEATURE_CUSTOMER_NAME_SHORTCUT=true --dart-define=FEATURE_TABLE_NUMBER=true --dart-define=FEATURE_PAY_LATER=true --dart-define=FEATURE_ORDERS_QUEUE=true --dart-define=FEATURE_ADMIN_POS_ACCESS=true --dart-define=FEATURE_CANCELLED_ORDERS_REPORT=true --dart-define=FEATURE_INVENTORY_MANAGEMENT_SETTING=true
```

Build APK release dengan semua fitur aktif:

```powershell
flutter build apk --release --dart-define=FEATURE_CUSTOMER_NAME_SHORTCUT=true --dart-define=FEATURE_TABLE_NUMBER=true --dart-define=FEATURE_PAY_LATER=true --dart-define=FEATURE_ORDERS_QUEUE=true --dart-define=FEATURE_ADMIN_POS_ACCESS=true --dart-define=FEATURE_CANCELLED_ORDERS_REPORT=true --dart-define=FEATURE_INVENTORY_MANAGEMENT_SETTING=true
```

Flag dapat diaktifkan satu per satu. Namun, `FEATURE_PAY_LATER` sebaiknya selalu
diaktifkan bersama `FEATURE_ORDERS_QUEUE`, karena pesanan belum lunas memerlukan
layar Pesanan untuk pelunasan, pembatalan, dan perubahan status.

## Verifikasi sebelum rilis reaktivasi

1. Jalankan `flutter analyze` dan `flutter test` menggunakan kombinasi flag yang
   akan dirilis.
2. Pastikan shortcut `Pelanggan Umum` hanya muncul pada role yang memang
   diizinkan oleh checkout.
3. Pastikan Dine In mewajibkan nomor meja ketika `FEATURE_TABLE_NUMBER=true`.
4. Pastikan Bayar Nanti menghasilkan order belum lunas tanpa payment,
   transaction, atau cetak struk ketika `FEATURE_PAY_LATER=true`.
5. Pastikan menu Pesanan muncul, order lama tetap terbaca, dan proses terima
   pembayaran/status/batal/cetak ulang berjalan ketika
   `FEATURE_ORDERS_QUEUE=true`.
6. Uji data lokal yang sudah memiliki `tableNumber` dan order `unpaid`; data
   tersebut harus tetap utuh selama fitur nonaktif maupun setelah reaktivasi.
7. Pastikan Admin hanya melihat menu POS ketika
   `FEATURE_ADMIN_POS_ACCESS=true`.
8. Pastikan kartu dan baris PDF pesanan dibatalkan hanya tampil ketika
   `FEATURE_CANCELLED_ORDERS_REPORT=true`.
9. Pastikan switch Pengelolaan Stok hanya tampil di Pengaturan Admin ketika
   `FEATURE_INVENTORY_MANAGEMENT_SETTING=true`; halaman Stok harus tetap aktif.

## Prompt reaktivasi siap pakai

```text
Aktifkan kembali fitur Talaga Coffee POS berikut melalui feature flags yang
sudah tersedia: [sebutkan fitur]. Jangan menghapus kompatibilitas data lama.
Aktifkan Bayar Nanti bersama Orders Queue, verifikasi akses Admin/Kasir,
validasi nomor meja Dine In bila fiturnya aktif, lalu jalankan flutter analyze
dan flutter test dengan dart-define yang sama. Perbarui PRD.md, FEATURES.md,
dan DEACTIVATED_FEATURES.md agar mencerminkan status akhir serta hasil uji.
```

## Catatan data dan rollback

- Tidak ada migrasi database pada penonaktifan ini.
- Nilai nomor meja dan order belum lunas yang sudah tersimpan tidak dihapus.
- Menonaktifkan kembali cukup dengan membangun aplikasi tanpa flag atau dengan
  nilai flag `false`.
- Selama Orders Queue nonaktif, order lama masih dapat muncul pada laporan/query
  internal, tetapi tidak dapat dikelola melalui UI Pesanan.
- Metrik pesanan belum lunas dihapus dari UI laporan dan PDF, tetapi field
  agregasinya tetap dipertahankan untuk kompatibilitas query dan data lama.
- Panel Reset Data hanya mengekspos kelompok SQLite yang dipakai UI: transaksi
  dan operasional kasir, log aktivitas/printer, serta katalog/persediaan.
  Keranjang aktif (state memori) dan penghapusan data pelanggan tidak lagi
  tersedia dari panel.

## Hasil verifikasi historis — 17 Juli 2026

- Build standar: 58 test lulus dan 4 test legacy Bayar Nanti dilewati karena
  `FEATURE_PAY_LATER=false`.
- Build reaktivasi terarah: 38 test lulus tanpa skip dengan keempat flag `true`.
- Navigasi Kasir compact tidak merender `NavigationBar` ketika Orders Queue
  nonaktif dan hanya tersisa satu tujuan efektif; regression test juga
  memastikan navigation bar kembali tampil saat Orders Queue diaktifkan.
- Static analysis: bersih (`No issues found`) setelah seluruh lint
  `use_build_context_synchronously` pada screen Orders/Settings diperbaiki.
