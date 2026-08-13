# Product Requirements

Requirement di dokumen ini adalah kontrak perilaku build standar. Gunakan ID stabil pada prompt, issue, test, dan changelog. Status fitur berada di `FEATURES.md`; lokasi implementasi berada di `docs/engineering/FEATURE_MAP.md`.

## Status

- `done`: behavior tersedia pada build standar.
- `partial`: behavior tersedia dengan cakupan yang diketahui terbatas.
- `planned`: sudah diputuskan sebagai arah produk, tetapi belum aktif.

## Fondasi, autentikasi, dan navigasi

| ID | Requirement | Status |
|---|---|---|
| FR-FND-01 | Aplikasi membuka database lokal, menjalankan migrasi, dan memastikan seed yang diperlukan sebelum workspace digunakan. | done |
| FR-FND-02 | Pengguna login dengan username/password lokal; akun nonaktif ditolak dan waktu login terakhir diperbarui. | done |
| FR-FND-03 | Instalasi baru menyediakan akun bootstrap Admin dan Kasir dari sumber konstanta/seed terpusat. | done |
| FR-FND-04 | Tujuan awal dan menu difilter berdasarkan role: Admin ke Dashboard, Kasir ke POS. | done |
| FR-FND-05 | Logout menghapus sesi in-memory, membersihkan keranjang, dan mengembalikan state navigasi awal. | done |
| FR-FND-06 | Workspace Admin/Kasir memiliki theme dan navigation yang sesuai role; dark mode tersimpan lokal. | done |
| FR-FND-07 | Bootstrap Firebase hanya berjalan ketika seluruh konfigurasi runtime eksternal tersedia dan project ID cocok dengan project Talaga yang disetujui; tanpa konfigurasi Firebase tetap nonaktif dan Drift tetap menjadi sumber data operasional. | partial |
| FR-FND-08 | Firestore menolak seluruh read/write secara default sampai Auth, App Check, model akses, dan scope sinkronisasi disetujui serta diverifikasi. | done |

## POS, keranjang, dan shift

| ID | Requirement | Status |
|---|---|---|
| FR-POS-01 | Kasir wajib membuka shift dengan modal awal sebelum memakai POS; shift aktif hanya dapat dipakai pemiliknya. | done |
| FR-POS-02 | Kasir dapat memilih tipe menu, kategori/subkategori, serta produk aktif dengan informasi harga dan stok. | done |
| FR-POS-03 | Produk mendukung opsi yang relevan: Hot/Ice, gula, add-on, jumlah, catatan, serta beans untuk Manual Brew. | done |
| FR-POS-04 | Harga Manual Brew ditentukan oleh beans dan pilihan Hot/Ice. | done |
| FR-POS-05 | Keranjang menggabungkan konfigurasi identik, menghitung subtotal, dan mendukung update/hapus/kosongkan. | done |
| FR-POS-06 | POS menggunakan dual-pane pada layar lebar dan akses cart adaptif pada layar compact. | done |
| FR-POS-07 | Kasir hanya dapat mencatat petty cash ketika memiliki shift aktif. | done |
| FR-POS-08 | Tutup shift menghitung expected cash, menerima uang fisik, menampilkan selisih, dan menyediakan keluaran thermal/PDF. | done |

## Checkout, pembayaran, dan struk

| ID | Requirement | Status |
|---|---|---|
| FR-CHK-01 | Checkout aktif mendukung Dine In dan Take Away serta mewajibkan nama pelanggan. | done |
| FR-CHK-02 | Pembayaran tunai memvalidasi uang dan stok yang dilacak, lalu menyimpan customer snapshot, order, items, payment, transaction, dan stock movement secara atomik. | done |
| FR-CHK-03 | Cetak struk dijalankan setelah commit; kegagalan printer tidak membatalkan transaksi finansial. | done |
| FR-CHK-04 | Cash drawer hanya dicoba sesuai konfigurasi dan kondisi checkout; kegagalan ditampilkan/dilog tanpa rollback transaksi. | done |
| FR-CHK-05 | Struk lunas mendukung ESC/POS 58/80 mm dan memuat identitas outlet, customer, order type, item/options, pembayaran, serta logo. | done |
| FR-CHK-06 | Kasir dapat meminta 1–10 salinan tambahan dan memakai shortcut jumlah salinan setelah pembayaran berhasil. | done |
| FR-CHK-07 | Quick cash menyediakan Uang Pas dan nominal Rupiah hasil pembulatan yang relevan terhadap total. | done |
| FR-CHK-08 | Input tunai hanya menerima angka, memformat pemisah ribuan, menjaga kursor, dan membatasi 12 digit. | done |
| FR-CHK-09 | Checkout/printer/cash-drawer menulis diagnostik yang cukup untuk troubleshooting lokal. | done |
| FR-CHK-10 | QRIS tetap tidak dapat dipilih/submit sampai integrasi merchant, konektivitas, dan rekonsiliasi disetujui. | planned |

## Dashboard, transaksi, dan laporan

| ID | Requirement | Status |
|---|---|---|
| FR-RPT-01 | Dashboard menampilkan omzet/transaksi hari ini, perbandingan periode, serta peringatan minimum stock. | done |
| FR-RPT-02 | Admin dapat memilih periode, melihat tren/distribusi, ranking produk, dan omzet kategori. | done |
| FR-RPT-03 | Riwayat Transaksi hanya menampilkan order lunas beserta detail order dan pembayaran. | done |
| FR-RPT-04 | Laporan mendukung preset dan rentang khusus untuk omzet, transaksi lunas, tunai diterima, produk terlaris, dan kategori. | done |
| FR-RPT-05 | Hanya order/payment lunas masuk omzet; kembalian tidak dihitung sebagai pemasukan. | done |
| FR-RPT-06 | Admin dapat mengekspor laporan PDF ke Downloads/Talaga Coffee dan aksi ekspor masuk audit trail. | done |

## Katalog dan inventory

| ID | Requirement | Status |
|---|---|---|
| FR-CAT-01 | Admin dapat CRUD/aktif-nonaktif produk dan mengatur kategori, harga, Manual Brew, inventory tracking, threshold, serta add-on. | done |
| FR-CAT-02 | Produk dengan histori terkait tidak boleh dihapus; produk tanpa histori membersihkan relasi mutable ketika dihapus. | done |
| FR-CAT-03 | Admin dapat mengelola kategori bertingkat, tipe, status, urutan, dan parent dengan validasi referensi. | done |
| FR-CAT-04 | Admin dapat mengelola add-on beserta harga dan status aktif. | done |
| FR-CAT-05 | Admin dapat mengelola beans beserta harga Hot/Ice dan status aktif. | done |
| FR-STK-01 | Admin dapat melihat current stock, status minimum, threshold, dan movement terbaru untuk produk tracked. | done |
| FR-STK-02 | Penyesuaian stock/threshold menulis movement dan audit event yang relevan. | done |

## Pengguna, audit, pengaturan, dan reset data

| ID | Requirement | Status |
|---|---|---|
| FR-USR-01 | Admin dapat melihat, membuat, mengubah, mengaktifkan/nonaktifkan, reset password, dan menghapus user Admin/Kasir. | done |
| FR-USR-02 | Sistem mempertahankan minimal satu Admin aktif dan melindungi akun sendiri, pemilik shift, serta user dengan histori terkait. | done |
| FR-AUD-01 | Admin dapat melihat daftar audit event terbaru. | done |
| FR-AUD-02 | Audit event minimal mencakup perubahan produk, penyesuaian/threshold stock, ekspor, operasi perangkat tertentu, dan reset. | partial |
| FR-SET-01 | Admin dapat mengubah identitas outlet dan footer struk. | done |
| FR-SET-02 | Kasir dapat meminta permission, memilih/connect printer, memilih kertas, dan test print. | done |
| FR-SET-03 | Kasir dapat mengaktifkan/test cash drawer serta melihat device log terbaru. | done |
| FR-SET-04 | Admin dapat reset kelompok transaksi, log, serta katalog/inventory setelah autentikasi ulang. | done |
| FR-SET-05 | Reset transaksi memulihkan dampak stock dan menghapus state operasional terkait tanpa merusak referensi katalog. | done |

## Non-functional requirements

| ID | Area | Requirement | Status |
|---|---|---|---|
| NFR-01 | Offline | Semua alur build standar berjalan dari storage lokal tanpa backend. | done |
| NFR-02 | Integrity | Unit bisnis all-or-nothing memakai transaction database; side effect platform berada di luar transaction. | done |
| NFR-03 | Migration | Upgrade dari schema lama yang didukung harus menjaga data dan memiliki jalur migrasi eksplisit. | done |
| NFR-04 | Security | Password tidak plaintext, akses dipisah role, akun nonaktif ditolak, dan reset meminta autentikasi Admin. | partial |
| NFR-05 | Peripheral resilience | Printer/cash drawer tidak boleh membatalkan commit finansial atau penutupan shift. | done |
| NFR-06 | Responsive UI | Layout mendukung kelas compact, expanded, large, dan extra-large serta tinggi layar terbatas. | done |
| NFR-07 | Localization | Locale utama Indonesia, UI berbahasa Indonesia, dan nominal memakai format Rupiah. | done |
| NFR-08 | Accessibility | Komponen baru menjaga semantics, focus/touch target, serta kontras theme terang/gelap. | partial |
| NFR-09 | Maintainability | Perubahan mengikuti lint, boundary arsitektur, code generation, test, dan dokumentasi repository. | done |
| NFR-10 | Production packaging | Build release menolak debug signing dan konfigurasi signing tidak lengkap; APK harus lulus verifikasi signature serta kecocokan fingerprint signer eksternal, sementara artifact produksi tetap memerlukan keystore resmi dan checklist perangkat terpisah. | partial |

## Acceptance lintas requirement

- Perilaku default dan kombinasi feature flag terkait harus deterministik.
- Transaksi finansial tidak boleh menghasilkan payment/transaction ganda.
- Histori order memakai snapshot agar perubahan master tidak mengubah transaksi lama.
- Error untuk pengguna harus menggunakan Bahasa Indonesia dan memberikan langkah pemulihan yang jelas.
- Perubahan yang memengaruhi requirement harus memperbarui ID terkait, test, registry fitur, dan feature map dalam task yang sama.
