# Product Requirements Document — Talaga Coffee POS

> Status: produk *as-is* pada 21 Juli 2026. Dokumen ini menjelaskan keputusan produk. Requirement rinci berada di `docs/product/REQUIREMENTS.md`; lokasi implementasi berada di `docs/engineering/FEATURE_MAP.md`.

## Ringkasan produk

Talaga Coffee POS adalah aplikasi point-of-sale Flutter offline-first untuk ponsel dan tablet Android. Operasi outlet utama tetap berjalan tanpa internet dan disimpan secara lokal melalui Drift/SQLite.

Produk menyediakan dua workspace:

- Kasir menjalankan shift, memilih produk, mengelola keranjang, menerima pembayaran tunai, mencetak struk, mencatat kas keluar, dan menutup shift.
- Admin memantau penjualan serta mengelola transaksi, laporan, katalog, stok, pengguna, aktivitas, identitas outlet, dan reset data.

## Masalah yang diselesaikan

1. Penjualan harus tetap dapat dicatat ketika koneksi internet tidak tersedia.
2. Kasir membutuhkan alur cepat dan aman dari pemilihan menu sampai pembayaran tunai.
3. Order, pembayaran, transaksi, stok, dan arus kas harus konsisten.
4. Admin membutuhkan kontrol operasional lokal tanpa masuk ke workspace kasir.
5. Kegagalan printer atau cash drawer tidak boleh menggagalkan pencatatan finansial.
6. Pergantian kasir perlu direkonsiliasi melalui modal awal, penjualan, kas keluar, uang fisik, dan selisih.

## Pengguna dan hak akses

| Role | Tanggung jawab aktif | Batas default |
|---|---|---|
| Admin | Dashboard, transaksi, laporan, katalog, stok, pengguna, audit, identitas outlet, reset data | Tidak mengakses POS serta panel printer/cash drawer |
| Kasir | Shift, POS, checkout tunai, petty cash, printer, cash drawer | Tidak mengakses modul admin atau reset destruktif |

Pelanggan adalah data yang melekat pada pesanan; belum tersedia workspace CRM pelanggan.

## Scope aktif

- Login lokal dan navigasi berbasis role.
- Seed akun, katalog, inventori, identitas outlet, dan printer bawaan.
- Buka/tutup shift, modal awal, petty cash, rekonsiliasi, laporan thermal, dan PDF shift.
- POS Minuman/Makanan, kategori, suhu, gula, Manual Brew berbasis beans, add-on, jumlah, dan catatan.
- Keranjang, nama pelanggan wajib, Dine In/Take Away, pembayaran tunai, quick cash, serta kembalian.
- Pengurangan/pemulihan stok, penyesuaian manual, minimum stock, dan stock movement.
- Struk ESC/POS 58/80 mm, logo thermal, cetak ulang, dan cash drawer melalui printer.
- Dashboard, transaksi lunas, laporan periode, grafik, ranking, serta ekspor PDF.
- CRUD produk, kategori, add-on, beans, dan pengguna.
- Audit trail dengan cakupan terbatas, printer log, dark mode, serta reset data granular.
- UI responsif berbasis role dengan bahasa utama Indonesia dan format Rupiah.

## Di luar scope aktif

- QRIS/DANA dan pembayaran online.
- CRM, loyalty, lookup/deduplikasi pelanggan, dan input nomor HP saat checkout.
- Diskon, promo, dan pajak yang dapat dikonfigurasi.
- Barcode/pencarian produk, delivery channel, serta bahan baku/recipe inventory.
- Cloud sync, backend API, multi-device, multi-outlet, dan conflict resolution.
- Target iOS, web, atau desktop.
- Production signing dan distribusi Play Store.

Fitur yang sengaja diparkir tidak termasuk scope build standar. Lihat `DEACTIVATED_FEATURES.md`.

## Prinsip produk

- Offline-first: alur aktif tidak bergantung pada backend.
- Financial integrity first: data transaksi menjadi sumber utama, periferal adalah side effect.
- Role clarity: workspace Kasir dan Admin tetap terpisah.
- Local data durability: perubahan schema harus menjaga instalasi lama.
- Operational speed: langkah checkout harus ringkas dan ramah layar sentuh.
- Indonesian-first UI: bahasa dan format uang mengikuti konteks outlet Indonesia.

## Batas kualitas yang sudah diketahui

- Unit/widget test dan static analysis tersedia; belum ada integration test perangkat nyata atau CI.
- Printer, cash drawer, MediaStore, dan upgrade database belum memiliki matriks end-to-end resmi.
- Release Android tidak lagi fallback ke debug signing, tetapi keystore resmi,
  signature artifact, dan instalasi release belum tersedia/terverifikasi.
- Belum ada target terukur untuk startup, latensi checkout, kapasitas data, retensi, backup, atau recovery time.

## Referensi keputusan

- Requirement aktif: `docs/product/REQUIREMENTS.md`
- Alur pengguna: `docs/product/USER_FLOWS.md`
- Pertanyaan yang belum diputuskan: `docs/product/OPEN_QUESTIONS.md`
- Registry fitur: `FEATURES.md`
- Fitur diparkir: `DEACTIVATED_FEATURES.md`
- Design system: `DESIGN.md`
