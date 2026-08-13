# Active Features Registry — Talaga Coffee POS

> Source of truth status fitur build standar per 21 Juli 2026. Hanya fitur yang dapat diakses pengguna pada konfigurasi default yang dicatat sebagai aktif. Fitur diparkir berada di `DEACTIVATED_FEATURES.md`.

## Legenda

- `active`: alur pengguna dan lapisan pendukung tersedia pada build standar.
- `partial`: sebagian alur tersedia atau cakupannya sengaja terbatas.

## Registry

| ID | Area | Fitur aktif | Role | Status |
|---|---|---|---|---|
| AUTH-01 | Auth | Login lokal berbasis username/password dan role | Admin, Kasir | active |
| AUTH-02 | Auth | Proteksi akun nonaktif dan shift milik kasir lain | Kasir | active |
| POS-01 | Shift | Buka shift dengan modal awal dan tutup shift dengan rekonsiliasi | Kasir | active |
| POS-02 | POS | Katalog Minuman/Makanan dengan kategori dan subkategori | Kasir | active |
| POS-03 | POS | Opsi Hot/Ice, gula, add-on, jumlah, catatan, dan Manual Brew berbasis beans | Kasir | active |
| POS-04 | Cart | Tambah, gabung, ubah, hapus, kosongkan, dan hitung subtotal | Kasir | active |
| POS-05 | Checkout | Dine In/Take Away, nama pelanggan wajib, dan pembayaran tunai langsung | Kasir | active |
| POS-06 | Checkout | Quick cash, input Rupiah, validasi uang, dan kembalian | Kasir | active |
| POS-07 | Cash | Petty cash selama shift aktif | Kasir | active |
| POS-08 | Receipt | Struk ESC/POS 58/80 mm, logo, salinan tambahan, dan cetak ulang | Kasir | active |
| POS-09 | Hardware | Printer Bluetooth, test print, cash drawer, dan device log | Kasir | active |
| ADM-01 | Dashboard | Ringkasan omzet/transaksi, perbandingan, grafik, ranking, dan low stock | Admin | active |
| ADM-02 | Transactions | Riwayat order lunas dan detail pembayaran | Admin | active |
| ADM-03 | Reports | Filter periode, metrik penjualan, ranking, kategori, dan ekspor PDF | Admin | active |
| CAT-01 | Catalog | CRUD kategori bertingkat | Admin | active |
| CAT-02 | Catalog | CRUD produk, harga, status, inventory tracking, dan Manual Brew | Admin | active |
| CAT-03 | Catalog | CRUD add-on dan relasi produk | Admin | active |
| CAT-04 | Catalog | CRUD beans dengan harga Hot/Ice | Admin | active |
| STK-01 | Inventory | Current stock, low-stock alert, threshold, dan movement history | Admin | active |
| STK-02 | Inventory | Restock/koreksi stok dan perubahan threshold | Admin | active |
| USR-01 | Users | CRUD, aktivasi, reset password, dan guard Admin terakhir/shift aktif | Admin | active |
| AUD-01 | Audit | Daftar audit event terbaru | Admin | partial |
| SET-01 | Settings | Identitas outlet dan footer struk | Admin | active |
| SET-02 | Settings | Dark mode persisten | Admin, Kasir | active |
| SET-03 | Data | Reset transaksi, log, serta katalog/persediaan secara granular | Admin | active |
| UI-01 | UI | Theme berbasis role, layout responsif, dan shared components | Admin, Kasir | active |

## Catatan cakupan

- `AUD-01` berstatus `partial` karena tidak semua event bisnis menulis audit log.
- QRIS dapat terlihat sebagai *coming soon*, tetapi bukan metode pembayaran aktif.
- Table/schema/provider lama tidak menjadikan sebuah fitur aktif tanpa entry point UI pada build standar.
- Registry ini tidak menyimpan lokasi file. Gunakan `docs/engineering/FEATURE_MAP.md` untuk ownership kode.
- Requirement dan acceptance criteria menggunakan ID di `docs/product/REQUIREMENTS.md`.

## Aturan perubahan status

Saat fitur berubah:

1. Perbarui registry ini hanya setelah alur build standar dan test relevan tersedia.
2. Perbarui `docs/product/REQUIREMENTS.md` bila behavior/acceptance berubah.
3. Perbarui `docs/engineering/FEATURE_MAP.md` bila ownership source berubah.
4. Jika fitur diparkir, pindahkan status operasionalnya ke `DEACTIVATED_FEATURES.md` tanpa menghapus data kompatibilitas secara otomatis.
5. Catat hasil verifikasi di `docs/quality/TESTING.md`.

