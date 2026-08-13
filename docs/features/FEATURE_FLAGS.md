# Feature Flags Contract

Semua flag didefinisikan di `lib/core/config/feature_flags.dart` dengan `bool.fromEnvironment`. Nilai dibaca saat build/run; perubahan membutuhkan build ulang.

## Registry

| Flag | Default | Efek saat `true` | Dependency |
|---|---|---|---|
| `FEATURE_CUSTOMER_NAME_SHORTCUT` | `false` | Menampilkan shortcut `Pelanggan Umum` | none |
| `FEATURE_TABLE_NUMBER` | `false` | Menampilkan/mevalidasi nomor meja pada Dine In | data lama table number |
| `FEATURE_PAY_LATER` | `false` | Mengizinkan checkout belum lunas | wajib bersama Orders Queue untuk rilis |
| `FEATURE_ORDERS_QUEUE` | `false` | Menampilkan menu/screen pengelolaan Pesanan | sebaiknya bersama Pay Later |
| `FEATURE_ADMIN_POS_ACCESS` | `false` | Mengizinkan Admin membuka POS | role/shift behavior harus diuji |
| `FEATURE_CANCELLED_ORDERS_REPORT` | `false` | Menampilkan metrik order dibatalkan di laporan/PDF | report queries |
| `FEATURE_INVENTORY_MANAGEMENT_SETTING` | `false` | Menampilkan switch inventory management | halaman stok tetap aktif tanpa flag |

## Command reaktivasi lengkap

```powershell
flutter run `
  --dart-define=FEATURE_CUSTOMER_NAME_SHORTCUT=true `
  --dart-define=FEATURE_TABLE_NUMBER=true `
  --dart-define=FEATURE_PAY_LATER=true `
  --dart-define=FEATURE_ORDERS_QUEUE=true `
  --dart-define=FEATURE_ADMIN_POS_ACCESS=true `
  --dart-define=FEATURE_CANCELLED_ORDERS_REPORT=true `
  --dart-define=FEATURE_INVENTORY_MANAGEMENT_SETTING=true
```

Untuk APK, ganti `flutter run` dengan `flutter build apk --release`. Untuk test enabled-state, gunakan `flutter test` dengan kombinasi `--dart-define` yang sama.

## Release matrix minimum

Setiap perubahan feature flag harus memverifikasi:

1. Build/test default tanpa flag.
2. Build/test dengan flag yang diubah bernilai `true`.
3. Kombinasi dependency, terutama Pay Later + Orders Queue.
4. Data lokal lama yang memiliki `tableNumber` atau order `unpaid` tetap utuh.
5. Role menu, route guard, dan mutation authorization.
6. Report/PDF hanya menampilkan metrik sesuai flag.
7. Menonaktifkan flag kembali tidak memerlukan destructive migration.

## Acceptance reaktivasi

### Customer shortcut

- Chip hanya muncul pada checkout dan mengisi nama sesuai keputusan produk.
- Nama manual tetap dapat digunakan.

### Table number

- Dine In meminta/menyimpan meja sesuai rule yang disetujui.
- Take Away tidak dipaksa memakai meja.
- Order lama tetap dapat dibaca.

### Pay Later + Orders Queue

- Order belum lunas tidak membuat payment, transaction, atau cetak struk lunas.
- Menu Pesanan tersedia untuk role yang disetujui.
- Terima pembayaran menghasilkan payment/transaction tepat satu kali.
- Update status, cancel, stock restore, dan reprint memiliki test.

### Admin POS

- Menu dan guard mengizinkan Admin hanya saat flag aktif.
- Perilaku shift Admin ditetapkan dan diuji eksplisit.
- Admin tidak memperoleh akses lain di luar scope flag.

### Report/settings flags

- UI dan PDF konsisten dengan nilai flag.
- Halaman Inventory tetap aktif ketika switch Settings disembunyikan.

## Documentation update

Jika fitur menjadi default aktif:

- Pindahkan status dari `DEACTIVATED_FEATURES.md` ke `FEATURES.md`.
- Tambahkan/perbarui requirement di `docs/product/REQUIREMENTS.md`.
- Perbarui flow, feature map, test evidence, serta PRD jika scope produk berubah.
- Hapus flag hanya setelah data compatibility dan rollback plan disetujui.

